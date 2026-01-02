@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '###GENERATED Core Data Service Entity'
@Metadata.allowExtensions: true

define view entity ZR_MSBOOKING
  as select from zmsbooking
  composition [0..*] of ZR_MSSUPPLEMENT          as _Supplement
  association        to parent ZR_MSTRAVEL       as _Travel on $projection.TravelUuid = _Travel.TravelUuid

  association [1..1] to /DMO/I_Customer          as _Customer      on $projection.CustomerId = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier           as _Airline       on $projection.CarrierId = _Airline.AirlineID
  association [1..1] to /DMO/I_Booking_Status_VH as _Status        on $projection.BookingStatus = _Status.BookingStatus

{
  key booking_uuid          as BookingUuid,

      travel_uuid           as TravelUuid,
      booking_id            as BookingId,
      booking_date          as BookingDate,
      customer_id           as CustomerId,
      carrier_id            as CarrierId,
      connection_id         as ConnectionId,
      flight_date           as FlightDate,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price          as FlightPrice,

      currency_code         as CurrencyCode,
      booking_status        as BookingStatus,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Supplement,
      _Travel,
      _Customer,
      _Airline,
      _Status
}
