
CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsupplement.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Booking RESULT result.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

  data max_booking_suppl_id type /dmo/booking_supplement_id.

    ""Step 1: get all the travel requests and their booking data
    read ENTITIES OF zats_ao_travel in local mode
        ENTITY booking by \_BookingSupplement
        from CORRESPONDING #( entities )
        link data(booking_supplements).

    ""Loop at unique travel ids
    loop at entities ASSIGNING FIELD-SYMBOL(<booking_group>) GROUP BY <booking_group>-%tky.
    ""Step 2: get the highest booking supplement number which is already there
        loop at booking_supplements into data(ls_booking) using key entity
            where source-TravelId = <booking_group>-TravelId and
                  source-BookingId = <booking_group>-BookingId.
                if max_booking_suppl_id < ls_booking-target-BookingId.
                    max_booking_suppl_id = ls_booking-target-BookingId.
                ENDIF.
        ENDLOOP.
    ""Step 3: get the asigned booking supplement numbers for incoming request
        loop at entities into data(ls_entity) using key entity
            where TravelId = <booking_group>-TravelId and
                  BookingId = <booking_group>-BookingId.
                loop at ls_entity-%target into data(ls_target).
                    if max_booking_suppl_id < ls_target-BookingId.
                        max_booking_suppl_id = ls_target-BookingId.
                    ENDIF.
                ENDLOOP.
        ENDLOOP.
    ""Step 4: loop over all the entities of travel with same travel id
        loop at entities ASSIGNING FIELD-SYMBOL(<booking>)
            USING KEY entity where TravelId = <booking_group>-TravelId and
                                   BookingId = <booking_group>-BookingId..
    ""Step 5: assign new booking IDs to the booking entity inside each travel
            LOOP at <booking>-%target ASSIGNING FIELD-SYMBOL(<bookingsuppl_wo_numbers>).
                append CORRESPONDING #( <bookingsuppl_wo_numbers> ) to mapped-booksuppl
                ASSIGNING FIELD-SYMBOL(<mapped_bookingsuppl>).
                if <mapped_bookingsuppl>-BookingSupplementId is INITIAL.
                    max_booking_suppl_id += 1.
                    <mapped_bookingsuppl>-BookingSupplementId = max_booking_suppl_id.
                ENDIF.
            ENDLOOP.
        ENDLOOP.
    ENDLOOP.


  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF ZATS_ao_TRAVEL IN LOCAL MODE
      ENTITY booking
         FIELDS ( CarrierId )
         WITH CORRESPONDING #( keys )
      RESULT DATA(bookings)
      FAILED failed.

    result = VALUE #( FOR booking IN bookings
                       ( %tky                   = booking-%tky
                         %field-CustomerId = COND #( WHEN booking-CarrierId = 'AA'
                                                          THEN if_abap_behv=>fc-f-read_only
                                                           ELSE if_abap_behv=>fc-f-unrestricted  ) ) ).


  ENDMETHOD.



ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
