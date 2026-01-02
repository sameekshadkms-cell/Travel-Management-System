@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '###GENERATED Core Data Service Entity'
@Metadata.allowExtensions: true

@ObjectModel.semanticKey: [ 'TravelId' ]

@Search.searchable: true
define root view entity ZC_MSTRAVEL 
provider contract transactional_query
 as projection on ZR_MSTRAVEL
{
  key TravelUuid,

      @ObjectModel.text.element: [ 'Description' ]
      @Search.defaultSearchElement: true
      TravelId,

      Description,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      _Agency.Name              as AgencyName,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Agency_StdVH', element: 'AgencyID' },
                                            useForValidation: true } ]
      @EndUserText.label: 'Agency'
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Search.defaultSearchElement: true
      AgencyId,

      _Customer.FirstName       as CustomerFirstName,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Customer_StdVH', element: 'CustomerID' },
                                            useForValidation: true } ]
      @EndUserText.label: 'Customer'
      @ObjectModel.text.element: [ 'CustomerFirstName' ]
      @Search.defaultSearchElement: true
      CustomerId,

      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      BeginDate,

      EndDate,
      BookingFee,
      TotalPrice,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CurrencyStdVH', element: 'Currency' },
                                            useForValidation: true } ]
      @Semantics.currencyCode: true
      CurrencyCode,

      _OverallStatus._Text.Text as OverallStatusText : localized,

      @Consumption.filter: { mandatory: true, defaultValue: 'O', multipleSelections: true }
      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Overall_Status_VH', element: 'OverallStatus' },
                                            useForValidation: true } ]
      @ObjectModel.text.element: [ 'OverallStatusText' ]
      OverallStatus,

      OverallStatusCriticality,
      Attachment,
      MimeType,
      FileName,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      _Booking : redirected to composition child ZC_MSBOOKING,
      _Attachment: redirected to composition child ZC_MSATTACH
}
