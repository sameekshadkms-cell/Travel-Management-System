@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'VIEW ENTITY FOR SUPPLEMENT'

@Metadata.allowExtensions: true

define view entity ZR_MSSUPPLEMENT
  as select from zms_booksp
  association        to parent ZR_MSBOOKING   as _Booking        on $projection.BookingUuid = _Booking.BookingUuid

  association [1..1] to ZR_MSTRAVEL           as _Travel         on $projection.TravelUuid = _Travel.TravelUuid
  association [1..1] to /DMO/I_Supplement     as _Product        on $projection.SupplementId = _Product.SupplementID
  association [1..*] to /DMO/I_SupplementText as _SupplementText on $projection.SupplementId = _SupplementText.SupplementID

{
  key supplement_uuid as SupplementUuid,

      travel_uuid     as TravelUuid,
      booking_uuid    as BookingUuid,
      supplement_id   as SupplementId,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      price           as Price,

      currency_code   as CurrencyCode,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,

      _Travel,
      _Booking,
      _Product,
      _SupplementText
}
