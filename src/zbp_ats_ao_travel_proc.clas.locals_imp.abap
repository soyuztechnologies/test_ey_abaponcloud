CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE Travel.
    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    types:  t_entity_create type table for create zats_ao_travel_processor,
          t_entity_update TYPE table for update zats_ao_travel_processor,
          t_entity_rep type table for REPORTED zats_ao_travel_processor,
          t_entity_err type table for FAILED zats_ao_travel_processor.

    methods precheck_anubhav_reuse
        importing
            entities_u type t_entity_update optional
            entities_c type t_entity_create optional
         exporting
            reported type t_entity_rep
            failed type t_entity_err.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

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

  METHOD augment_create.

    data: travel_create type table for create zats_ao_travel.

     travel_create = CORRESPONDING #( entities ).

     loop at travel_create assigning field-symbol(<travel>).

        <travel>-AgencyId = '70003'.
        <travel>-OverallStatus = 'O'.
        <travel>-%control-AgencyId = if_abap_behv=>mk-on.
        <travel>-%control-OverallStatus = if_abap_behv=>mk-on.

     ENDLOOP.

     MODIFY augmenting entities of zats_ao_travel
     entity travel
     create from travel_create.


  ENDMETHOD.

ENDCLASS.
