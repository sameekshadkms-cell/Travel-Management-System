@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '###GENERATED Core Data Service Entity'
@Metadata.allowExtensions: true
define view entity ZC_MSSUPPLEMENT as projection on ZR_MSSUPPLEMENT
{
  key SupplementUuid,

      TravelUuid,
      BookingUuid,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Supplement_StdVH', element: 'SupplementID' },
                                            additionalBinding: [ { localElement: 'Price',
                                                                   element: 'Price',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                   element: 'CurrencyCode',
                                                                   usage: #RESULT } ],
                                            useForValidation: true } ]
      @ObjectModel.text.element: [ 'SupplementDescription' ]
      SupplementId,

      _SupplementText.Description as SupplementDescription : localized, Price,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CurrencyStdVH', element: 'Currency' },
                                            useForValidation: true } ]
      CurrencyCode,

      LastChangedAt,

      /* Associations */
      _Booking : redirected to parent ZC_MSBOOKING,
      _Travel: redirected to ZC_MSTRAVEL
}
