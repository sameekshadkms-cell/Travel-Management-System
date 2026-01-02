@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '###GENERATED Core Data Service Entity'
@Metadata.allowExtensions: true
define view entity ZC_MSBOOKING as projection on ZR_MSBOOKING
{
  key BookingUuid,

      TravelUuid,
      BookingId,
      BookingDate,
      _Customer.FirstName as CustomerFirstName,

      // _Customer.LastName  as CustomerLastName,
      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Customer_StdVH', element: 'CustomerID' },
                                            useForValidation: true } ]
      @ObjectModel.text.element: [ 'CustomerFirstName' ]
      CustomerId,

      _Airline.Name       as AirlineName,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Flight_StdVH', element: 'AirlineID' },
                                            useForValidation: true,
                                            additionalBinding: [ { localElement: 'FlightDate',
                                                                   element: 'FlightDate',
                                                                   usage: #RESULT },
                                                                 { localElement: 'ConnectionId',
                                                                   element: 'ConnectionID',
                                                                   usage: #RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                   element: 'Price',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                   element: 'CurrencyCode',
                                                                   usage: #RESULT } ] } ]
      @ObjectModel.text.element: [ 'AirlineName' ]
      CarrierId,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Flight_StdVH', element: 'ConnectionID' },
                                            additionalBinding: [ { localElement: 'FlightDate',
                                                                   element: 'FlightDate',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CarrierId',
                                                                   element: 'AirlineID',
                                                                   usage: #FILTER_AND_RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                   element: 'Price',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                   element: 'CurrencyCode',
                                                                   usage: #RESULT } ],
                                            useForValidation: true } ]
      ConnectionId,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Flight_StdVH', element: 'FlightDate' },
                                            additionalBinding: [ { localElement: 'ConnectionId',
                                                                   element: 'ConnectionID',
                                                                   usage: #FILTER_AND_RESULT },
                                                                 { localElement: 'CarrierId',
                                                                   element: 'AirlineID',
                                                                   usage: #FILTER_AND_RESULT },
                                                                 { localElement: 'FlightPrice',
                                                                   element: 'Price',
                                                                   usage: #RESULT },
                                                                 { localElement: 'CurrencyCode',
                                                                   element: 'CurrencyCode',
                                                                   usage: #RESULT } ],
                                            useForValidation: true } ]
      FlightDate,

      FlightPrice,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CurrencyStdVH', element: 'Currency' },
                                            useForValidation: true } ]
      CurrencyCode,

      _Status._Text.Text  as StatusText : localized,

      @Consumption.valueHelpDefinition: [ { entity: { name: '/DMO/I_Booking_Status_VH', element: 'BookingStatus' },
                                            useForValidation: true } ]
      @ObjectModel.text.element: [ 'StatusText' ]
      BookingStatus,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      _Travel : redirected to parent ZC_MSTRAVEL,
      _Supplement : redirected to composition child ZC_MSSUPPLEMENT
}
