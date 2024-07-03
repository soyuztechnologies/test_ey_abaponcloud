@EndUserText.label: 'My Travel processor projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_ao_BOOKING_PROCESSOR as projection on ZATS_AO_BOOKING
{
    key TravelId,
    key BookingId,
    BookingDate,
    @Consumption.valueHelpDefinition: [{ 
        entity.name: '/DMO/I_Customer',
        entity.element: 'CustomerID'
     }]
    CustomerId,
    @Consumption.valueHelpDefinition: [{ 
        entity.name: '/DMO/I_Carrier',
        entity.element: 'AirlineID'
     }]
    CarrierId,
    @Consumption.valueHelpDefinition: [{ 
        entity.name: '/DMO/I_Connection',
        entity.element: 'ConnectionID',
        additionalBinding: [
                            { localElement: 'CarrierId',
                              element: 'AirlineID' }
                           ]
     }]
    ConnectionId,
    FlightDate,
    FlightPrice,
    CurrencyCode,
    @Consumption.valueHelpDefinition: [{ 
        entity.name: '/DMO/I_Booking_Status_VH',
        entity.element: 'BookingStatus'
     }]
    BookingStatus,
    LastChangedAt,
    /* Associations */
    _BookingStatus,
    _BookingSupplement: redirected to composition child ZATS_AO_BOOKSUPPL_PROCESSOR,
    _Carrier,
    _Connection,
    _Customer,
    _Travel: redirected to parent ZATS_AO_TRAVEL_PROCESSOR
}
