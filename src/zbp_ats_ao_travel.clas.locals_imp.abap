CLASS lsc_zats_ao_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zats_ao_travel IMPLEMENTATION.

  METHOD save_modified.

    DATA: travel_log_update TYPE STANDARD TABLE OF /dmo/log_travel,
          final_changes     TYPE STANDARD TABLE OF /dmo/log_travel.

    IF create-travel is not INITIAL.

       LOOP AT create-travel ASSIGNING FIELD-SYMBOL(<travel_log_update>).

          APPEND value #(
            change_id = cl_system_uuid=>create_uuid_x16_static( )
            changed_field_name = 'anubhav_new_travel'
            changed_value = <travel_log_update>-TravelId
            changing_operation = 'CREATE'
           )
           TO final_changes.
       ENDLOOP.

       INSERT /dmo/log_travel FROM TABLE @final_changes.

    ENDIF.

    IF update-travel IS NOT INITIAL.

      travel_log_update = CORRESPONDING #( update-travel MAPPING
                                              travel_id = TravelId
       ).

      LOOP AT update-travel ASSIGNING <travel_log_update>.

        ASSIGN travel_log_update[ travel_id = <travel_log_update>-TravelId ]
            TO FIELD-SYMBOL(<travel_log_db>).

        GET TIME STAMP FIELD <travel_log_db>-created_at.

        IF <travel_log_update>-%control-CustomerId = if_abap_behv=>mk-on.

          <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
          <travel_log_db>-changed_field_name = 'anubhav_customer'.
          <travel_log_db>-changed_value = <travel_log_update>-CustomerId.
          <travel_log_db>-changing_operation = 'CHANGE'.

          APPEND <travel_log_db> TO final_changes.

        ENDIF.

        IF <travel_log_update>-%control-AgencyId = if_abap_behv=>mk-on.

          <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
          <travel_log_db>-changed_field_name = 'anubhav_agency'.
          <travel_log_db>-changed_value = <travel_log_update>-AgencyId.
          <travel_log_db>-changing_operation = 'CHANGE'.

          APPEND <travel_log_db> TO final_changes.

        ENDIF.

      ENDLOOP.

      INSERT /dmo/log_travel FROM TABLE @final_changes.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.
    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calculatetotalprice.
    METHODS validateheaderdata FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateheaderdata.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE travel.
    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~accepttravel RESULT result.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejecttravel RESULT result.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_booking.

    types:  t_entity_create type table for create zats_ao_travel,
              t_entity_update TYPE table for update zats_ao_travel,
              t_entity_rep type table for REPORTED zats_ao_travel,
              t_entity_err type table for FAILED zats_ao_travel.

    methods precheck_anubhav_reuse
        importing
            entities_u type t_entity_update optional
            entities_c type t_entity_create optional
         exporting
            reported type t_entity_rep
            failed type t_entity_err.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    data : ls_result like line of result.

    "Step 1: Get the data of my instance
    READ ENTITIES OF zats_ao_travel in LOCAL MODE
        ENTITY travel
            fields ( travelid OverallStatus )
                WITH CORRESPONDING #( keys )
                    RESULT data(lt_travel)
                    FAILED data(ls_failed).

    "Step 2: loop at the data
    loop at lt_travel into data(ls_travel).

        "Step 3: Check if the instance was having status = cancelled
        if ( ls_travel-OverallStatus = 'X' ).
            data(lv_auth) = abap_false.

            "Step 4: Check for authorization in org
*            AUTHORITY-CHECK OBJECT 'CUSTOM_OBJ'
*                ID 'FIELD_NAME' FIELD field1
*            IF sy-subrc = 0.
*                lv_auth = abap_true.
*            ENDIF.
        else.
            lv_auth = abap_true.
        ENDIF.

        ls_result = value #( TravelId = ls_travel-TravelId
                             %action-Edit = COND #( when lv_auth eq abap_false
                                                    then if_abap_behv=>auth-unauthorized
                                                    else    if_abap_behv=>auth-allowed
                                             )
                             %action-copyTravel = COND #( when lv_auth eq abap_false
                                                    then if_abap_behv=>auth-unauthorized
                                                    else    if_abap_behv=>auth-allowed
                                             )
        ).

        ""Finally send the result out to RAP
        APPEND ls_result to result.

    ENDLOOP.


  ENDMETHOD.

  METHOD earlynumbering_create.

    data: entity type STRUCTURE FOR CREATE zats_ao_travel,
          travel_id_max type /dmo/travel_id.

    ""Step 1: Ensure that Travel id is not set for the record which is coming
    loop at entities into entity where TravelId is not initial.
        APPEND CORRESPONDING #( entity ) to mapped-travel.
    ENDLOOP.

    data(entities_wo_travelid) = entities.
    delete entities_wo_travelid where TravelId is not INITIAL.

    ""Step 2: Get the seuquence numbers from the SNRO
    try.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL' )
            quantity          =  conv #( lines( entities_wo_travelid ) )
          IMPORTING
            number            = data(number_range_key)
            returncode        = data(number_range_return_code)
            returned_quantity = data(number_range_returned_quantity)
        ).
*        CATCH cx_nr_object_not_found.
*        CATCH cx_number_ranges.

      catch cx_number_ranges into data(lx_number_ranges).
        ""Step 3: If there is an exception, we will throw the error
        loop at entities_wo_travelid into entity.
            append value #( %cid = entity-%cid %key = entity-%key %msg = lx_number_ranges )
                to reported-travel.
            append value #( %cid = entity-%cid %key = entity-%key ) to failed-travel.
        ENDLOOP.
        exit.
    endtry.

    case number_range_return_code.
        when '1'.
            ""Step 4: Handle especial cases where the number range exceed critical %
            loop at entities_wo_travelid into entity.
                append value #( %cid = entity-%cid %key = entity-%key
                                %msg = new /dmo/cm_flight_messages(
                                            textid = /dmo/cm_flight_messages=>number_range_depleted
                                            severity = if_abap_behv_message=>severity-warning
                                ) )
                    to reported-travel.
            ENDLOOP.
        when '2' OR '3'.
            ""Step 5: The number range return last number, or number exhaused
            append value #( %cid = entity-%cid %key = entity-%key
                                %msg = new /dmo/cm_flight_messages(
                                            textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                            severity = if_abap_behv_message=>severity-warning
                                ) )
                    to reported-travel.
            append value #( %cid = entity-%cid
                            %key = entity-%key
                            %fail-cause = if_abap_behv=>cause-conflict
                             ) to failed-travel.
    ENDCASE.

    ""Step 6: Final check for all numbers
    ASSERT number_range_returned_quantity = lines( entities_wo_travelid ).

    ""Step 7: Loop over the incoming travel data and asign the numbers from number range and
    ""        return MAPPED data which will then go to RAP framework
    travel_id_max = number_range_key - number_range_returned_quantity.

    loop at entities_wo_travelid into entity.

        travel_id_max += 1.
        entity-TravelId = travel_id_max.

        reported-%other = VALUE #( ( new_message_with_text(
                                 severity = if_abap_behv_message=>severity-success
                                 text     = 'Travel id has been created now!' ) ) ).

        append value #( %cid = entity-%cid
                        %is_draft = entity-%is_draft
                        %key = entity-%key ) to mapped-travel.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    data max_booking_id type /dmo/booking_id.

    ""Step 1: get all the travel requests and their booking data
    read ENTITIES OF zats_ao_travel in local mode
        ENTITY travel by \_Booking
        from CORRESPONDING #( entities )
        link data(bookings).

    ""Loop at unique travel ids
    loop at entities ASSIGNING FIELD-SYMBOL(<travel_group>) GROUP BY <travel_group>-TravelId.
    ""Step 2: get the highest booking number which is already there
        loop at bookings into data(ls_booking) using key entity
            where source-TravelId = <travel_group>-TravelId.
                if max_booking_id < ls_booking-target-BookingId.
                    max_booking_id = ls_booking-target-BookingId.
                ENDIF.
        ENDLOOP.
    ""Step 3: get the asigned booking numbers for incoming request
        loop at entities into data(ls_entity) using key entity
            where TravelId = <travel_group>-TravelId.
                loop at ls_entity-%target into data(ls_target).
                    if max_booking_id < ls_target-BookingId.
                        max_booking_id = ls_target-BookingId.
                    ENDIF.
                ENDLOOP.
        ENDLOOP.
    ""Step 4: loop over all the entities of travel with same travel id
        loop at entities ASSIGNING FIELD-SYMBOL(<travel>)
            USING KEY entity where TravelId = <travel_group>-TravelId.
    ""Step 5: assign new booking IDs to the booking entity inside each travel
            LOOP at <travel>-%target ASSIGNING FIELD-SYMBOL(<booking_wo_numbers>).
                append CORRESPONDING #( <booking_wo_numbers> ) to mapped-booking
                ASSIGNING FIELD-SYMBOL(<mapped_booking>).
                if <mapped_booking>-BookingId is INITIAL.
                    max_booking_id += 10.
                    <mapped_booking>-%is_draft = <booking_wo_numbers>-%is_draft.
                    <mapped_booking>-BookingId = max_booking_id.
                ENDIF.
            ENDLOOP.
        ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.
    "Step 1: Read the travel data with status
    READ ENTITIES OF zats_ao_travel in local mode
        ENTITY travel
            FIELDS ( travelid overallstatus )
            with     CORRESPONDING #( keys )
        RESULT data(travels)
        FAILED failed.

    "Step 2: return the result with booking creation possible or not
    read table travels into data(ls_travel) index 1.

    if ( ls_travel-OverallStatus = 'X' ).
        data(lv_allow) = if_abap_behv=>fc-o-disabled.
        data(lv_enable) = if_abap_behv=>fc-f-read_only.
    else.
        lv_allow = if_abap_behv=>fc-o-enabled.
        lv_enable = if_abap_behv=>fc-f-unrestricted.
    ENDIF.

    result = value #( for travel in travels
                        ( %tky = travel-%tky
                        %action-acceptTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                                            then if_abap_behv=>fc-o-disabled
                                                                            else if_abap_behv=>fc-o-enabled
                          )
                          %action-rejectTravel = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                            then if_abap_behv=>fc-o-disabled
                                                                            else if_abap_behv=>fc-o-enabled
                          )
                          %assoc-_Booking = lv_allow
                        )
                    ).
  ENDMETHOD.

  METHOD copyTravel.

    DATA:
      travels       TYPE TABLE FOR CREATE ZATS_AO_TRAVEL\\travel,
      bookings_cba  TYPE TABLE FOR CREATE ZATS_AO_TRAVEL\\travel\_booking,
      booksuppl_cba TYPE TABLE FOR CREATE ZATS_AO_TRAVEL\\Booking\_BookingSupplement.

    " remove travel instances with initial %cid (i.e., not set by caller API)
    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_inital_cid).
    ASSERT key_with_inital_cid IS INITIAL.

    READ ENTITIES OF ZATS_AO_TRAVEL IN LOCAL MODE
      ENTITY travel
       ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travel_read_result)
    FAILED failed.

    READ ENTITIES OF ZATS_AO_TRAVEL IN LOCAL MODE
      ENTITY travel BY \_booking
       ALL FIELDS WITH CORRESPONDING #( travel_read_result )
     RESULT DATA(book_read_result).

    READ ENTITIES OF ZATS_AO_TRAVEL IN LOCAL MODE
      ENTITY booking BY \_BookingSupplement
       ALL FIELDS WITH CORRESPONDING #( book_read_result )
    RESULT DATA(booksuppl_read_result).

    LOOP AT travel_read_result ASSIGNING FIELD-SYMBOL(<travel>).
      "Fill travel container for creating new travel instance
      APPEND VALUE #( %cid     = keys[ %tky = <travel>-%tky ]-%cid
                      %data    = CORRESPONDING #( <travel> EXCEPT travelid ) )
        TO travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      "Fill %cid_ref of travel as instance identifier for cba booking
      APPEND VALUE #( %cid_ref = keys[  %tky = <travel>-%tky ]-%cid )
        TO bookings_cba ASSIGNING FIELD-SYMBOL(<bookings_cba>).

      <new_travel>-begindate     = cl_abap_context_info=>get_system_date( ).
      <new_travel>-enddate       = cl_abap_context_info=>get_system_date( ) + 30.
      <new_travel>-overallstatus = 'O'.  "Set to open to allow an editable instance

      LOOP AT book_read_result ASSIGNING FIELD-SYMBOL(<booking>) USING KEY entity WHERE travelid EQ <travel>-travelid.
        "Fill booking container for creating booking with cba
        APPEND VALUE #( %cid     = keys[ %tky = <travel>-%tky ]-%cid && <booking>-bookingid
                        %data    = CORRESPONDING #(  book_read_result[ %tky = <booking>-%tky ] EXCEPT travelid ) )
          TO <bookings_cba>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).

        "Fill %cid_ref of booking as instance identifier for cba booksuppl
        APPEND VALUE #( %cid_ref = keys[ %tky = <travel>-%tky ]-%cid && <booking>-bookingid )
          TO booksuppl_cba ASSIGNING FIELD-SYMBOL(<booksuppl_cba>).

        <new_booking>-bookingstatus = 'N'.

        LOOP AT booksuppl_read_result ASSIGNING FIELD-SYMBOL(<booksuppl>) USING KEY entity WHERE travelid  EQ <travel>-travelid
                                                                                           AND   bookingid EQ <booking>-bookingid.
          "Fill booksuppl container for creating supplement with cba
          APPEND VALUE #( %cid  = keys[ %tky = <travel>-%tky ]-%cid  && <booking>-bookingid && <booksuppl>-bookingsupplementid
                          %data = CORRESPONDING #( <booksuppl> EXCEPT travelid bookingid ) )
            TO <booksuppl_cba>-%target.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

    "create new BO instance
    MODIFY ENTITIES OF ZATS_AO_TRAVEL IN LOCAL MODE
      ENTITY travel
        CREATE FIELDS ( agencyid customerid begindate enddate bookingfee totalprice currencycode overallstatus description )
          WITH travels
        CREATE BY \_Booking FIELDS ( bookingid bookingdate customerid carrierid connectionid flightdate flightprice currencycode bookingstatus )
          WITH bookings_cba
      ENTITY booking
        CREATE BY \_BookingSupplement FIELDS ( bookingsupplementid supplementid price currencycode )
          WITH booksuppl_cba
      MAPPED DATA(mapped_create).

    mapped-travel   =  mapped_create-travel .

  ENDMETHOD.

  METHOD reCalcTotalPrice.

*    Define a structure where we can store all the booking fees and currency code
     TYPES : BEGIN OF ty_amount_per_currency,
                amount type /dmo/total_price,
                currency_code type /dmo/currency_code,
             END OF ty_amount_per_currency.

     data : amounts_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currency.

*    Read all travel instances, subsequent bookings using EML
     READ ENTITIES OF ZATS_ao_TRAVEL IN LOCAL MODE
        ENTITY Travel
        FIELDS ( BookingFee CurrencyCode )
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

     READ ENTITIES OF ZATS_ao_TRAVEL IN LOCAL MODE
        ENTITY Travel by \_Booking
        FIELDS ( FlightPrice CurrencyCode )
        WITH CORRESPONDING #( travels )
        RESULT DATA(bookings).

     READ ENTITIES OF ZATS_ao_TRAVEL IN LOCAL MODE
        ENTITY Booking by \_BookingSupplement
        FIELDS ( price CurrencyCode )
        WITH CORRESPONDING #( bookings )
        RESULT DATA(bookingsupplements).

*    Delete the values w/o any currency
     DELETE travels WHERE CurrencyCode is initial.
     DELETE bookings WHERE CurrencyCode is initial.
     DELETE bookingsupplements WHERE CurrencyCode is initial.

*    Total all booking and supplement amounts which are in common currency
     loop at travels ASSIGNING FIELD-SYMBOL(<travel>).
     "Set the first value for total price by adding the booking fee from header
     amounts_per_currencycode = value #( ( amount = <travel>-BookingFee
                                         currency_code = <travel>-CurrencyCode ) ).

*    Loop at all amounts and compare with target currency
        loop at bookings into data(booking) where TravelId = <travel>-TravelId.

            COLLECT VALUE ty_amount_per_currency( amount = booking-FlightPrice
                                                  currency_code = booking-CurrencyCode
            ) into amounts_per_currencycode.

        ENDLOOP.

        loop at bookingsupplements into data(bookingsupplement) where TravelId = <travel>-TravelId.

            COLLECT VALUE ty_amount_per_currency( amount = bookingsupplement-Price
                                                  currency_code = booking-CurrencyCode
            ) into amounts_per_currencycode.

        ENDLOOP.

        clear <travel>-TotalPrice.
*    Perform currency conversion
        loop at amounts_per_currencycode into data(amount_per_currencycode).

            if amount_per_currencycode-currency_code = <travel>-CurrencyCode.
                <travel>-TotalPrice += amount_per_currencycode-amount.
            else.

                /dmo/cl_flight_amdp=>convert_currency(
                  EXPORTING
                    iv_amount               = amount_per_currencycode-amount
                    iv_currency_code_source = amount_per_currencycode-currency_code
                    iv_currency_code_target = <travel>-CurrencyCode
                    iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
                  IMPORTING
                    ev_amount               = data(total_booking_amt)
                ).

                <travel>-TotalPrice = <travel>-TotalPrice + total_booking_amt.
            ENDIF.

        ENDLOOP.
*    Put back the total amount

     ENDLOOP.
*    Return the total amount in mapped so the RAP will modify this data to DB
     MODIFY ENTITIES OF    ZATS_ao_TRAVEL in local mode
     entity travel
     UPDATE FIELDS ( TotalPrice )
     WITH CORRESPONDING #( travels ).


  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY entities of ZATS_AO_TRAVEL in local mode
        ENTITY travel
            execute reCalcTotalPrice
            FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD validateHeaderData.


    "Step 1: Read the travel data
    read entities of ZATS_AO_TRAVEL in local mode
        ENTITY travel
        FIELDS ( CustomerId )
        WITH CORRESPONDING #( keys )
        RESULT data(lt_travel).

    "Step 2: Declare a sorted table for holding customer ids
    data customers type SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    "Step 3: Extract the unique customer IDs in our table
    customers = CORRESPONDING #( lt_travel discarding duplicates mapping
                                       customer_id = CustomerId EXCEPT *
     ).
    delete customers where customer_id is INITIAL.

    ""Get the validation done to get all customer ids from db
    ""these are the IDs which are present
    if customers is not initial.

        select from /dmo/customer FIELDS customer_id
        FOR ALL ENTRIES IN @customers
        where customer_id = @customers-customer_id
        into table @data(lt_cust_db).

    ENDIF.

    ""loop at travel data
    loop at lt_travel into data(ls_travel).

        if ( ls_travel-CustomerId is initial OR
             NOT  line_exists(  lt_cust_db[ customer_id = ls_travel-CustomerId ] ) ).

            ""Inform the RAP framework to terminate the create
            append value #( %tky = ls_travel-%tky ) to failed-travel.
            append value #( %tky = ls_travel-%tky
                            %element-customerid = if_abap_behv=>mk-on
                            %msg = new /dmo/cm_flight_messages(
                                          textid                = /dmo/cm_flight_messages=>customer_unkown
                                          customer_id           = ls_travel-CustomerId
                                          severity              = if_abap_behv_message=>severity-error

            )
            ) to reported-travel.

        ENDIF.

    ENDLOOP.

    ""Exercise: Validations
    "1. check if begin and end date is empty
    "2. check if the end date is always > begin date
    "3. begin date of travel should be in future


  ENDMETHOD.

  METHOD precheck_create.

    precheck_anubhav_reuse(
      EXPORTING
*        entities_u =
         entities_c = entities
      IMPORTING
        reported   = reported-travel
        failed     = failed-travel
    ).

  ENDMETHOD.

  METHOD precheck_update.

    precheck_anubhav_reuse(
      EXPORTING
          entities_u = entities
*         entities_c =
      IMPORTING
        reported   = reported-travel
        failed     = failed-travel
    ).

  ENDMETHOD.

  METHOD precheck_anubhav_reuse.


    ""Step 1: Data declaration
    data: entities type t_entity_update,
           operation type if_abap_behv=>t_char01,
           agencies type sorted table of /dmo/agency WITH UNIQUE KEY agency_id,
           customers type sorted table of /dmo/customer WITH UNIQUE key customer_id.

    ""Step 2: Check either entity_c was passed or entity_u was passed
    ASSERT not ( entities_c is initial equiv entities_u is initial ).

    ""Step 3: Perform validation only if agency OR customer was changed
    if entities_c is not initial.
        entities = CORRESPONDING #( entities_c ).
        operation = if_abap_behv=>op-m-create.
    else.
        entities = CORRESPONDING #( entities_u ).
        operation = if_abap_behv=>op-m-update.
    ENDIF.

    delete entities where %control-AgencyId = if_abap_behv=>mk-off and
                          %control-CustomerId = if_abap_behv=>mk-off.

    ""Step 4: get all the unique agencies and customers in a table
    agencies = CORRESPONDING #( entities discarding DUPLICATES MAPPING agency_id = AgencyId EXCEPT * ).
    customers = CORRESPONDING #( entities discarding DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).

    ""Step 5: Select the agency and customer data from DB tables
    select from /dmo/agency fields agency_id, country_code
    for all ENTRIES IN @agencies where agency_id = @agencies-agency_id
    into table @data(agency_country_codes).

    select from /dmo/customer fields customer_id, country_code
    for all ENTRIES IN @customers where customer_id = @customers-customer_id
    into table @data(customer_country_codes).

    ""Step 6: Loop at incoming entities and compare each agency and customer country
    loop at entities into data(entity).
        read table agency_country_codes with key agency_id = entity-AgencyId into data(ls_agency).
        CHECK sy-subrc = 0.
        read table customer_country_codes with key customer_id = entity-CustomerId into data(ls_customer).
        CHECK sy-subrc = 0.
        if ls_agency-country_code <> ls_customer-country_code.
            ""Step 7: if country doesnt match, throw the error
            append value #(    %cid = cond #( when operation = if_abap_behv=>op-m-create then entity-%cid_ref )
                                      %is_draft = entity-%is_draft
                                      %fail-cause = if_abap_behv=>cause-conflict
              ) to failed.

            append value #(    %cid = cond #( when operation = if_abap_behv=>op-m-create then entity-%cid_ref )
                                      %is_draft = entity-%is_draft
                                      %msg = new /dmo/cm_flight_messages(
                                                                                              textid                = value #(
                                                                                                                                     msgid = 'SY'
                                                                                                                                     msgno = 499
                                                                                                                                     attr1 = 'The country codes for agency and customer not matching'
                                                                                                                                  )
                                                                                              agency_id             = entity-AgencyId
                                                                                              customer_id           = entity-CustomerId
                                                                                              severity  = if_abap_behv_message=>severity-error
                                                                                            )
                                      %element-agencyid = if_abap_behv=>mk-on
              ) to reported.

        ENDIF.
    ENDLOOP.


  ENDMETHOD.

  METHOD acceptTravel.
  ""Perform the change of BO instance to change status
    MODIFY ENTITIES OF zats_ao_travel
        ENTITY travel
            UPDATE FIELDS ( OverallStatus )
            WITH VALUE #( for key in keys ( %tky = key-%tky
                                                        %is_draft = key-%is_draft
                                                        OverallStatus = 'A'
             )  ).
    ""Read the BO instance on which we want to make the changes
    READ ENTITIES OF zats_ao_travel
        ENTITY Travel
            ALL FIELDS
                WITH CORRESPONDING #( keys )
                    RESULT data(lt_results).

    result = value #( for travel in lt_results ( %tky = travel-%tky
                                                          %param = travel
    ) ).

  ENDMETHOD.

  METHOD rejectTravel.

  ""Perform the change of BO instance to change status
    MODIFY ENTITIES OF zats_ao_travel
        ENTITY travel
            UPDATE FIELDS ( OverallStatus )
            WITH VALUE #( for key in keys ( %tky = key-%tky
                                                        %is_draft = key-%is_draft
                                                        OverallStatus = 'X'
             )  ).
    ""Read the BO instance on which we want to make the changes
    READ ENTITIES OF zats_ao_travel
        ENTITY Travel
            ALL FIELDS
                WITH CORRESPONDING #( keys )
                    RESULT data(lt_results).

    result = value #( for travel in lt_results ( %tky = travel-%tky
                                                          %param = travel
    ) ).

  ENDMETHOD.

ENDCLASS.
