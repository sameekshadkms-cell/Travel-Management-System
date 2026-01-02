CLASS lhc_zrmstravel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O', " Open
        accepted TYPE c LENGTH 1 VALUE 'A', " Accepted
        rejected TYPE c LENGTH 1 VALUE 'X', " Rejected
      END OF travel_status.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING REQUEST requested_authorizations FOR zrmstravel RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zrmstravel RESULT result.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE zrmstravel.

    METHODS GetDefaultsForDeductDiscount FOR READ
      IMPORTING keys FOR FUNCTION zrmstravel~GetDefaultsForDeductDiscount RESULT result.

    METHODS CopyTravel FOR MODIFY
      IMPORTING keys FOR ACTION zrmstravel~CopyTravel.

    METHODS DeductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION zrmstravel~DeductDiscount RESULT result.

    METHODS ReCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION zrmstravel~ReCalcTotalPrice.

    METHODS SetStatusToAccepted FOR MODIFY
      IMPORTING keys FOR ACTION zrmstravel~SetStatusToAccepted RESULT result.

    METHODS SetStatusToRejected FOR MODIFY
      IMPORTING keys FOR ACTION zrmstravel~SetStatusToRejected RESULT result.

METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
IMPORTING keys FOR zrmstravel~CalculateTotalPrice.

    METHODS SetStatusToOpen FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zrmstravel~SetStatusToOpen.

    METHODS SetTravelNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR zrmstravel~SetTravelNumber.

    METHODS ValidateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR zrmstravel~ValidateCustomer.

    METHODS ValidateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR zrmstravel~ValidateDates.


ENDCLASS.

CLASS lhc_zrmstravel IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
          ENTITY zrmstravel
          FIELDS ( overallstatus )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels)
          FAILED failed.

    result = VALUE #( FOR travel IN travels
                      ( %tky                        = travel-%tky

                        %features-%update           = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %features-%delete           = COND #( WHEN travel-OverallStatus = travel_status-open
                                                              THEN if_abap_behv=>fc-o-enabled
                                                              ELSE if_abap_behv=>fc-o-disabled )

                        %action-Edit                = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %action-SetStatusToAccepted = COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %action-SetStatusToRejected = COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )

                        %action-DeductDiscount      = COND #( WHEN travel-OverallStatus = travel_status-open
                                                              THEN if_abap_behv=>fc-o-enabled
                                                              ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

  METHOD precheck_update.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-Description IS INITIAL OR strlen( <travel>-Description ) > 1.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky    = <travel>-%tky
                      %update = if_abap_behv=>mk-on ) TO failed-zrmstravel.

      APPEND VALUE #(
          %tky                 = <travel>-%tky
          %msg                 = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'Description should be more than 1 characters' )
          %update              = if_abap_behv=>mk-on
          %element-Description = if_abap_behv=>mk-on ) TO reported-zrmstravel.
    ENDLOOP.
  ENDMETHOD.

  METHOD GetDefaultsForDeductDiscount.
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
          ENTITY zrmstravel
          FIELDS ( TravelUuid )
          WITH CORRESPONDING #( keys )
          RESULT DATA(lt_travels).

    LOOP AT lt_travels INTO DATA(ls_travel).
      DATA(lv_discount) = VALUE decan(  ).
      IF ls_travel-TotalPrice >=  5000.
        lv_discount = 20.
      ELSE.
        lv_discount = 15.
      ENDIF.
      APPEND VALUE #( %tky                    = ls_travel-%tky
                      %param-discount_percent = lv_discount )
             TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD CopyTravel.
    DATA new_travels  TYPE TABLE FOR CREATE zr_mstravel\\zrmstravel.
    DATA new_bookings TYPE TABLE FOR CREATE zr_mstravel\\zrmstravel\_Booking.

    " remove travel instances with initial %cid (i.e., not set by caller API)
    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_inital_cid).
    ASSERT key_with_inital_cid IS INITIAL.

    " read the data from the travel instances to be copied
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(travels)
         FAILED failed.

    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel BY \_Booking ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(bookings)
         FAILED failed.

    "%CID -Content ID is temporary key for an instance,its valid till actual primary key is not generated by runtime.
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      " fill in travel container for creating new travel instance
      APPEND VALUE #( %cid      = keys[ KEY draft
                                        %tky = <travel>-%tky ]-%cid
                      %is_draft = keys[ KEY draft
                                        %tky = <travel>-%tky ]-%is_draft
                      %data     = CORRESPONDING #( <travel> EXCEPT TravelUuid TravelId ) )
             TO new_travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      "%CID_REF - Specifies reference to content ID. If need to refer header and child record then %CID_REF is populated with header %CID value.
      " Fill %cid of travel as instance identifier for %cid_ref of cba booking
      APPEND VALUE #( %cid_ref = keys[ KEY draft
                                       %tky = <travel>-%tky ]-%cid )
             TO new_bookings ASSIGNING FIELD-SYMBOL(<bookings_cba>).

      " adjust the copied travel instance data
      " BeginDate must be on or after system date
      <new_travel>-BeginDate     = cl_abap_context_info=>get_system_date( ).
      " EndDate must be after BeginDate
      <new_travel>-EndDate       = cl_abap_context_info=>get_system_date( ) + 30.
      " OverallStatus of new instances must be set to open ('O')
      <new_travel>-OverallStatus = travel_status-open.

      LOOP AT bookings ASSIGNING FIELD-SYMBOL(<booking>) WHERE TravelUuid = <travel>-TravelUuid.
        " Fill booking container for creating booking with cba
        APPEND VALUE #( %cid  = keys[ KEY draft
                                      %tky = <travel>-%tky ]-%cid && <booking>-BookingUuid
                        %data = CORRESPONDING #(  bookings[ KEY draft
                                                            %tky = <booking>-%tky ] EXCEPT BookingUuid TravelUuid ) )
               TO <bookings_cba>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).

        <new_booking>-BookingStatus = 'N'.
      ENDLOOP.
    ENDLOOP.

    " create new BO instance
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate BookingFee
                             TotalPrice CurrencyCode OverallStatus Description )
           WITH new_travels
           CREATE BY \_Booking FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId
                                       FlightDate FlightPrice CurrencyCode BookingStatus )
           WITH new_bookings
           MAPPED DATA(mapped_create).

    " set the new BO instances
    mapped-zrmstravel = mapped_create-zrmstravel.
  ENDMETHOD.

  METHOD DeductDiscount.
    DATA travels_for_update TYPE TABLE FOR UPDATE zr_mstravel.

    DATA(keys_with_valid_discount) = keys.

    " check and handle invalid discount values
    LOOP AT keys_with_valid_discount ASSIGNING FIELD-SYMBOL(<key_with_valid_discount>)
         WHERE %param-discount_percent IS INITIAL OR %param-discount_percent > 100 OR %param-discount_percent <= 0.

      " report invalid discount value appropriately
      APPEND VALUE #( %tky = <key_with_valid_discount>-%tky ) TO failed-zrmstravel.

      APPEND VALUE #( %tky                       = <key_with_valid_discount>-%tky
                      %msg                       = new_message_with_text("NEW /dmo/cm_flight_messages(
                                                           "textid   = /dmo/cm_flight_messages=>discount_invalid
                                                     text   =   'Invalid Discount! Please enter a value b/w 1 & 100.'
                                                           severity = if_abap_behv_message=>severity-error )
                      %element-TotalPrice        = if_abap_behv=>mk-on  " Indicates the exact field or element within a BO instance that caused an error.
                      %op-%action-deductDiscount = if_abap_behv=>mk-on ) " Indicates that the message was caused by a custom action deductDiscount
             TO reported-zrmstravel.

      " remove invalid discount value
      DELETE keys_with_valid_discount.
    ENDLOOP.

    " check and go ahead with valid discount values
    IF keys_with_valid_discount IS INITIAL.
      RETURN.
    ENDIF.

    " read relevant travel instance data (only booking fee)
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel
         FIELDS ( BookingFee )
         WITH CORRESPONDING #( keys_with_valid_discount )
         RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      DATA percentage TYPE decfloat16.
      DATA(discount_percent) = keys_with_valid_discount[ KEY draft
                                                         %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percent / 100.
      DATA(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ).

      APPEND VALUE #( %tky       = <travel>-%tky
                      BookingFee = reduced_fee )
             TO travels_for_update.
    ENDLOOP.

    " update data with reduced fee
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           UPDATE FIELDS ( BookingFee )
           WITH travels_for_update.

    " read changed data for action result
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel
         ALL FIELDS
         WITH CORRESPONDING #( travels )
         RESULT DATA(travels_with_discount).

    " set action result
    result = VALUE #( FOR travel IN travels_with_discount
                      ( %tky   = travel-%tky
                        %param = travel ) ).
  ENDMETHOD.

  METHOD ReCalcTotalPrice.
    TYPES: BEGIN OF ty_amount_per_currencycode,
             amount        TYPE /dmo/total_price,
             currency_code TYPE /dmo/currency_code,
           END OF ty_amount_per_currencycode.

    DATA amount_per_currencycode TYPE STANDARD TABLE OF ty_amount_per_currencycode.

    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel
         FIELDS ( BookingFee CurrencyCode )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_travels).

    "DELETE lt_travels WHERE CurrencyCode IS INITIAL.
    LOOP AT lt_travels ASSIGNING FIELD-SYMBOL(<fs_travel>).
      " Set the start for the calculation by adding the booking fee.
      CLEAR amount_per_currencycode.
      amount_per_currencycode = VALUE #( ( amount        = <fs_travel>-BookingFee
                                           currency_code = <fs_travel>-CurrencyCode ) ).

      READ ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           BY \_Booking
           FIELDS ( FlightPrice CurrencyCode )
           WITH VALUE #( ( %tky = <fs_travel>-%tky ) )
           RESULT DATA(lt_bookings).


      LOOP AT lt_bookings ASSIGNING FIELD-SYMBOL(<fs_booking>).
        COLLECT VALUE ty_amount_per_currencycode( amount        = <fs_booking>-FlightPrice
                                                  currency_code = <fs_booking>-CurrencyCode )
                INTO amount_per_currencycode.
      ENDLOOP.


      DATA lt_booking_keys TYPE TABLE FOR READ IMPORT zr_msbooking\_Supplement.
      lt_booking_keys = VALUE #(
        FOR booking IN lt_bookings
        ( %tky = booking-%tky )
      ).
      IF lt_booking_keys IS NOT INITIAL.

        " 6. Read all supplements for these bookings
        READ ENTITIES OF zr_mstravel IN LOCAL MODE
             ENTITY zrmsbooking
             BY \_Supplement
             FIELDS ( Price CurrencyCode )
             WITH lt_booking_keys
             RESULT DATA(lt_supplements).

        " 7. Add supplement prices
        LOOP AT lt_supplements ASSIGNING FIELD-SYMBOL(<fs_supplement>).
          COLLECT VALUE ty_amount_per_currencycode(
                   amount        = <fs_supplement>-Price
                   currency_code = <fs_supplement>-CurrencyCode )
            INTO amount_per_currencycode.
        ENDLOOP.

      ENDIF.

      CLEAR <fs_travel>-TotalPrice.
      LOOP AT amount_per_currencycode INTO DATA(single_amount_per_currencycode).
        " If needed do a Currency Conversion
        " IF single_amount_per_currencycode-currency_code = <fs_travel>-CurrencyCode.
        <fs_travel>-TotalPrice += single_amount_per_currencycode-amount.
        "  ELSE.
*          /dmo/cl_flight_amdp=>convert_currency(
*            EXPORTING iv_amount               = single_amount_per_currencycode-amount
*                      iv_currency_code_source = single_amount_per_currencycode-currency_code
*                      iv_currency_code_target = <fs_travel>-CurrencyCode
*                      iv_exchange_rate_date   =  '20251201' "cl_abap_context_info=>get_system_date( )
*            IMPORTING ev_amount               = DATA(total_booking_price_per_curr) ).
*          <fs_travel>-TotalPrice += total_booking_price_per_curr.
*        ENDIF.
      ENDLOOP.

    ENDLOOP.

    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           UPDATE FIELDS ( TotalPrice )
           WITH VALUE #( FOR travel IN lt_travels (
                           %tky       = travel-%tky
                           TotalPrice = travel-TotalPrice
                       ) ).
        "   WITH CORRESPONDING #( lt_travels ).
  ENDMETHOD.

  METHOD SetStatusToAccepted.
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           UPDATE FROM VALUE #( FOR key IN keys
                                ( TravelUuid             = key-TravelUuid
                                  OverallStatus          = travel_status-accepted " Accepted
                                  %control-OverallStatus = if_abap_behv=>mk-on ) )
           FAILED failed
           REPORTED reported.

    " Read changed data for action result
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels
                      ( %tky   = travel-%tky
                        %param = travel ) ).
  ENDMETHOD.

  METHOD SetStatusToRejected.
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
            ENTITY zrmstravel
            UPDATE FROM VALUE #( FOR key IN keys
                                 ( TravelUuid             = key-TravelUuid
                                   OverallStatus          = travel_status-rejected " Rejected
                                   %control-OverallStatus = if_abap_behv=>mk-on ) )
            FAILED failed
            REPORTED reported.

    " Read changed data for action result
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel
         ALL FIELDS WITH
         CORRESPONDING #( keys )
         RESULT DATA(travels).

    result = VALUE #( FOR travel IN travels
                      ( %tky   = travel-%tky
                        %param = travel ) ).
  ENDMETHOD.

Method CalculateTotalPrice.
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
            ENTITY zrmstravel
            EXECUTE ReCalcTotalPrice
            FROM CORRESPONDING #( keys ).
  ENDMETHOD.

  METHOD SetStatusToOpen.
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
          ENTITY zrmstravel
          FIELDS ( OverallStatus )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels)
          " TODO: variable is assigned but never used (ABAP cleaner)
          FAILED DATA(read_failed).

    " If overall travel status is already set, do nothing, i.e. remove such instances
    DELETE travels WHERE OverallStatus IS NOT INITIAL.
    IF travels IS INITIAL.
      RETURN.
    ENDIF.

    " else set overall travel status to open ('O')
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           UPDATE FIELDS ( OverallStatus )
           WITH VALUE #( FOR travel IN travels
                         ( %tky          = travel-%tky
                           OverallStatus = travel_status-open ) )
           REPORTED DATA(update_reported).

    " Set the changing parameter
    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD SetTravelNumber.
    DATA travel_id_max TYPE /dmo/travel_id.

    " Ensure idempotence
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmstravel
         FIELDS ( TravelID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    DATA(entities_wo_travelid) = travels.
    DELETE entities_wo_travelid WHERE TravelID IS NOT INITIAL.
    IF entities_wo_travelid IS INITIAL.
      RETURN.
    ENDIF.

    " Get Numbers
    TRY.
        cl_numberrange_runtime=>number_get( EXPORTING nr_range_nr       = '01'
                                                      object            = '/DMO/TRV_M'
                                                      quantity          = CONV #( lines( entities_wo_travelid ) )
                                            IMPORTING number            = DATA(number_range_key)
                                                      returncode        = DATA(number_range_return_code)
                                                      returned_quantity = DATA(number_range_returned_quantity) ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        LOOP AT entities_wo_travelid INTO DATA(entity).
          APPEND VALUE #( %tky = entity-%tky
                          %msg = lx_number_ranges )
                 TO reported-zrmstravel.
        ENDLOOP.
        RETURN.
    ENDTRY.

    CASE number_range_return_code.
      WHEN '1'.
        " 1 - the returned number is in a critical range (specified under “percentage warning” in the object definition)
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %tky = entity-%tky
                          %msg = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>number_range_depleted
                                                              severity = if_abap_behv_message=>severity-warning ) )
                 TO reported-zrmstravel.
        ENDLOOP.

      WHEN '2' OR '3'.
        " 2 - the last number of the interval was returned
        " 3 - if fewer numbers are available than requested,  the return code is 3
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %tky = entity-%tky
                          %msg = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>not_sufficient_numbers
                                                              severity = if_abap_behv_message=>severity-warning ) )
                 TO reported-zrmstravel.
        ENDLOOP.
        RETURN.
    ENDCASE.

    " At this point ALL entities get a number!
    ASSERT number_range_returned_quantity = lines( entities_wo_travelid ).
    travel_id_max = number_range_key - number_range_returned_quantity.

    " update involved instances
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           UPDATE FIELDS ( TravelID )
           WITH VALUE #( FOR travel IN travels INDEX INTO i
                         ( %tky     = travel-%tky
                           TravelId = travel_id_max + i ) ).
  ENDMETHOD.

  METHOD ValidateCustomer.

    READ ENTITIES OF zr_mstravel IN LOCAL MODE
          ENTITY zrmstravel
          FIELDS ( CustomerId )
          WITH CORRESPONDING #( keys )
          RESULT DATA(lt_travels).

    DATA customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = CORRESPONDING #( lt_travels DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.

    IF customers IS NOT INITIAL.
      " Check if customer ID is valid
      SELECT FROM /dmo/customer
        FIELDS customer_id
        FOR ALL ENTRIES IN @customers
        WHERE customer_id = @customers-customer_id
        INTO TABLE @DATA(lt_valid_customers).
    ENDIF.

    LOOP AT lt_travels INTO DATA(ls_travel).

      APPEND VALUE #( %tky        = ls_travel-%tky
                      %state_area = 'VALIDATE_CUSTOMER' )
             TO reported-zrmstravel.

      IF ls_travel-CustomerId IS INITIAL.

        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-zrmstravel.

        APPEND VALUE #(
            %tky                = ls_travel-%tky
            %state_area         = 'VALIDATE_CUSTOMER'
            %msg                = NEW /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                               severity = if_abap_behv_message=>severity-error )

            %element-customerid = if_abap_behv=>mk-on )
               TO reported-zrmstravel.
      ELSEIF ls_travel-CustomerID IS NOT INITIAL AND NOT line_exists(
                                                             lt_valid_customers[ customer_id = ls_travel-customerid ] ).
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-zrmstravel.

        APPEND VALUE #( %tky                = ls_travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = NEW /dmo/cm_flight_messages(
                                                      customer_id = ls_travel-customerid
                                                      textid      = /dmo/cm_flight_messages=>customer_unkown
                                                      severity    = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on )
               TO reported-zrmstravel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD ValidateDates.
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel
           FIELDS ( BeginDate EndDate )
           WITH CORRESPONDING #( keys )
           RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      APPEND VALUE #( %tky        = travel-%tky
                      %state_area = 'VALIDATE_DATES' ) TO reported-zrmstravel.

      IF travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrmstravel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                     textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                     severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-zrmstravel.

      ENDIF.

      IF travel-BeginDate < cl_abap_context_info=>get_system_date( ) AND travel-BeginDate IS NOT INITIAL.

        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrmstravel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                     begin_date = travel-BeginDate
                                                     textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                     severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-zrmstravel.

      ENDIF.

      IF travel-EndDate IS INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrmstravel.

        APPEND VALUE #( %tky             = travel-%tky
                        %state_area      = 'VALIDATE_DATES'
                        %msg             = NEW /dmo/cm_flight_messages(
                                                   textid   = /dmo/cm_flight_messages=>enter_end_date
                                                   severity = if_abap_behv_message=>severity-error )
                        %element-EndDate = if_abap_behv=>mk-on ) TO reported-zrmstravel.
      ENDIF.

      IF     travel-EndDate  < travel-BeginDate AND travel-BeginDate IS NOT INITIAL
         AND travel-EndDate IS NOT INITIAL.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-zrmstravel.

        APPEND VALUE #( %tky               = travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                     textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                     begin_date = travel-BeginDate
                                                     end_date   = travel-EndDate
                                                     severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-zrmstravel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


ENDCLASS.

CLASS lhc_zrmsbooking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zrmsbooking RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zrmsbooking RESULT result.

     METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
     IMPORTING keys FOR zrmsbooking~CalculateTotalPrice.

    METHODS SetCustomerId FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zrmsbooking~SetCustomerId.

    METHODS SetBookingNumber FOR DETERMINE ON SAVE
      IMPORTING keys FOR zrmsbooking~SetBookingNumber.

    METHODS validateFlightNumber FOR VALIDATE  ON SAVE
      IMPORTING keys FOR zrmsbooking~validateFlightNumber.

    METHODS validate_flight_date FOR VALIDATE ON SAVE
    IMPORTING keys FOR zrmsbooking~validateflightdate.

*    METHODS recalc_totalprice FOR DETERMINE ON MODIFY
*      IMPORTING keys FOR  zrmsbooking~ReCalcTotalPrice.

ENDCLASS.

CLASS lhc_zrmsbooking IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD CalculateTotalPrice.
    " Read all travels for the requested bookings
    " If multiple bookings of the same travel are requested, the travel is returned only once.
*    READ ENTITIES OF zr_mstravel IN LOCAL MODE
*         ENTITY zrmsbooking BY \_Travel
*         FIELDS ( TravelUUID )
*         WITH CORRESPONDING #( keys )
*         RESULT DATA(lt_travels).
*
*    " update involved instances
*    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
*           ENTITY zrmstravel
*           EXECUTE recalctotalprice
*           FROM CORRESPONDING #( lt_travels ).
  "ENDMETHOD.
" 12/28/2025"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
DATA travels TYPE TABLE FOR ACTION IMPORT zr_mstravel~ReCalcTotalPrice.

  " 1. Loop through the keys of the deleted/modified bookings
  LOOP AT keys INTO DATA(ls_key).

    " 2. Try to 'rescue' the TravelUUID from the Draft Table (zmsbooking_d)
    "    (Even if we are deleting it, the DB record usually still exists at this split second)
    SELECT single traveluuid
      FROM zmsbooking_d
      WHERE bookinguuid = @ls_key-Bookinguuid
      INTO @DATA(lv_travel_uuid).

*    " 3. If not found in Draft, try the Active Table (fallback)
    IF sy-subrc <> 0.
      SELECT SINGLE travel_uuid
        FROM zmsbooking
        WHERE booking_uuid = @ls_key-BookingUuid
        INTO @lv_travel_uuid.
    ENDIF.
*
    " 4. If we found a parent, add it to the list to be updated
    IF lv_travel_uuid IS NOT INITIAL.
      APPEND VALUE #( %tky-TravelUuid = lv_travel_uuid
                      %tky-%is_draft  = ls_key-%is_draft ) " Preserve draft state
             TO travels.
    ENDIF.
  ENDLOOP.
*
  " 5. Trigger the Parent Calculation ONLY if we found valid parents
  IF travels IS NOT INITIAL.
    " Sort and delete duplicates to prevent calculating the same parent twice
    SORT travels BY %tky.
    DELETE ADJACENT DUPLICATES FROM travels COMPARING %tky.

    " Execute the action on the Parent
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
      ENTITY zrmstravel
      EXECUTE ReCalcTotalPrice
      FROM travels.
  ENDIF.
  ENDMETHOD.
  METHOD SetCustomerId.
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
          ENTITY zrmsbooking BY \_Travel
          ALL FIELDS " FIELDS ( CustomerId )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels).

    IF travels[ 1 ]-customerId IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmsbooking
           UPDATE FIELDS ( CustomerId )
           WITH VALUE #( FOR key IN keys
                         ( %tky                = key-%tky
                           CustomerId          = travels[ 1 ]-CustomerId
                           %control-CustomerId = if_abap_behv=>mk-on ) )
           REPORTED DATA(update_reported).

    " Set the changing parameter
    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD SetBookingNumber.

    DATA max_bookingid   TYPE /dmo/booking_id.
    DATA bookings_update TYPE TABLE FOR UPDATE zr_mstravel\\zrmsbooking.

    " Read all travels for the requested bookings
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
         ENTITY zrmsbooking BY \_Travel
         FIELDS ( TravelUUID )
         WITH CORRESPONDING #( keys )
         RESULT DATA(travels).

    " Process all affected travels. Read respective bookings for one travel
    LOOP AT travels INTO DATA(travel).
      READ ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmstravel BY \_Booking
           FIELDS ( BookingID )
           WITH VALUE #( ( %tky = travel-%tky ) )
           RESULT DATA(bookings).

      " find max used bookingID in all bookings of this travel
      max_bookingid = '0000'.
      LOOP AT bookings INTO DATA(booking).
        IF booking-BookingID > max_bookingid.
          max_bookingid = booking-BookingID.
        ENDIF.
      ENDLOOP.

      " Provide a booking ID for all bookings of this travel that have none.
      LOOP AT bookings INTO booking WHERE BookingID IS INITIAL.
        max_bookingid += 1.
        APPEND VALUE #( %tky      = booking-%tky
                        BookingID = max_bookingid )
               TO bookings_update.
      ENDLOOP.
    ENDLOOP.

    " Provide a booking ID for all bookings that have none.
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
           ENTITY zrmsbooking
           UPDATE FIELDS ( BookingID )
           WITH bookings_update.
  ENDMETHOD.

  METHOD validateFlightNumber.
    " 1. Read the Booking data to check the Flight Number (connection_id)
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
      ENTITY zrmsbooking
      FIELDS ( ConnectionId ) WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    LOOP AT bookings INTO DATA(booking).
      " 2. Check if Flight Number is empty
      IF booking-ConnectionId IS INITIAL.

        " 3. Add to FAILED (stops the save)
        APPEND VALUE #( %tky = booking-%tky ) TO failed-zrmsbooking.

        " 4. Add to REPORTED (shows the message on UI)
        APPEND VALUE #(
            %tky = booking-%tky
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-error
                     text     = 'Flight Number is mandatory while Booking.'
                   )
            %element-ConnectionId = if_abap_behv=>mk-on
        ) TO reported-zrmsbooking.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate_flight_date.

    DATA(today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zr_mstravel
      ENTITY zrmsbooking
        FIELDS ( flightdate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(bookings).

    LOOP AT bookings INTO DATA(booking).
      IF booking-flightdate < today.
        APPEND VALUE #(
          %key = booking-%key
          %msg = new_message_with_text(
                    severity = if_abap_behv_message=>severity-error
                   text = 'Flight date cannot be in the past.'
                 )
            %element-flightdate = if_abap_behv=>mk-on
        ) TO reported-zrmsbooking.
        APPEND VALUE #( %tky = booking-%tky ) TO failed-zrmsbooking.
        "APPEND booking-%key TO failed-zrmsbooking.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.



*"To triggere Supplements

*CLASS lhc_zrmssupplement IMPLEMENTATION.
*  METHOD recalc_totalprice.
*    READ ENTITIES OF zr_mstravel IN LOCAL MODE
*      ENTITY zrmssupplement BY \_Travel
*        FIELDS ( TravelUuid )
*        WITH CORRESPONDING #( keys )
*      RESULT DATA(supplements).
*
**    IF supplements IS INITIAL.
**      RETURN.
**    ENDIF.
*    SORT supplements BY TravelUuid.
*    DELETE ADJACENT DUPLICATES FROM supplements COMPARING TravelUuid.
*
*    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
*      ENTITY zrmstravel
*        EXECUTE ReCalcTotalPrice
*        FROM VALUE #( FOR travel IN supplements
*                      ( %tky-TravelUuid = travel-TravelUuid ) ).
*  ENDMETHOD.
*
ENDCLASS.

CLASS lhc_zrmssupplement DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS CalculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR zrmssupplement~CalculateTotalPrice.
ENDCLASS.
CLASS lhc_zrmssupplement IMPLEMENTATION.

  METHOD CalculateTotalPrice.
    " 1. Read the Parent Travel via the direct association
    READ ENTITIES OF zr_mstravel IN LOCAL MODE
      ENTITY zrmssupplement BY \_Travel
      FIELDS ( TravelUuid )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    " 2. Remove duplicates (in case multiple supplements of same travel were changed)
    SORT travels BY TravelUuid.
    DELETE ADJACENT DUPLICATES FROM travels COMPARING TravelUuid.

    " 3. Trigger the Parent Recalculation
    MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
      ENTITY zrmstravel
      EXECUTE ReCalcTotalPrice
      FROM CORRESPONDING #( travels ).

DATA trip TYPE TABLE FOR ACTION IMPORT zr_mstravel~ReCalcTotalPrice.

    LOOP AT keys INTO DATA(ls_key).

      " 1. Try to find the Parent in the DRAFT table first
      "    (Note: Your draft table 'zms_booksp_d' uses column names WITHOUT underscores)
      SELECT SINGLE traveluuid
        FROM zms_booksp_d
        WHERE supplementuuid = @ls_key-SupplementUuid
        INTO @DATA(lv_travel_uuid).

      " 2. If not found, try the ACTIVE table as a fallback
      "    (Note: Your active table 'zms_booksp' uses column names WITH underscores)
      IF sy-subrc <> 0.
        SELECT SINGLE travel_uuid
          FROM zms_booksp
          WHERE supplement_uuid = @ls_key-SupplementUuid
          INTO @lv_travel_uuid.
      ENDIF.

      " 3. If we found the parent Travel UUID, add it to the list
      IF lv_travel_uuid IS NOT INITIAL.
        APPEND VALUE #( %tky-TravelUuid = lv_travel_uuid
                        %tky-%is_draft  = ls_key-%is_draft )
               TO trip.
      ENDIF.

    ENDLOOP.

    " 4. Trigger the Parent to Recalculate
    IF trip IS NOT INITIAL.
      " Sort and remove duplicates to avoid calculating the same Travel multiple times
      SORT trip BY %tky.
      DELETE ADJACENT DUPLICATES FROM trip COMPARING %tky.

      " Execute the calculation action on the Parent
      MODIFY ENTITIES OF zr_mstravel IN LOCAL MODE
        ENTITY zrmstravel
        EXECUTE ReCalcTotalPrice
        FROM trip.
    ENDIF.

     ENDMETHOD.
ENDCLASS.
