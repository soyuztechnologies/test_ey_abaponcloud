@EndUserText.label: 'My Travel processor projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZATS_AO_TRAVEL_PROCESSOR
  provider contract transactional_query as projection on ZATS_AO_TRAVEL
{
    @ObjectModel.text.element: [ 'Description' ]
    key TravelId,
    @ObjectModel.text.element: [ 'AgencyName' ]
    @Consumption.valueHelpDefinition: [{ 
        entity.name: '/DMO/I_Agency',
        entity.element: 'AgencyID'
     }]
    AgencyId,
    @Semantics.text: true
    _Agency.Name as AgencyName,
    @ObjectModel.text.element: [ 'CustomerName' ]
    @Consumption.valueHelpDefinition: [{ 
        entity.name: '/DMO/I_Customer',
        entity.element: 'CustomerID'
     }]
    CustomerId,
    @Semantics.text: true
    _Customer.LastName as CustomerName,
    BeginDate,
    EndDate,
    BookingFee,
    TotalPrice,
    CurrencyCode,
    @Semantics.text: true
    Description,
    @Consumption.valueHelpDefinition: [{ 
        entity.name: '/DMO/I_Overall_Status_VH',
        entity.element: 'OverallStatus'
     }]
    @ObjectModel.text.element: [ 'StatusText' ]
    OverallStatus,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    @Semantics.text: true
    StatusText,
    Criticality,
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_AO_CALC'
    @EndUserText.label: 'CO2 Tax'
    virtual CO2Tax : abap.int4,
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_AO_CALC'
    @EndUserText.label: 'Week Day'
    virtual dayOfTheFlight : abap.char( 9 ),
    /* Associations */
    _Agency,
    _Booking: redirected to composition child ZATS_ao_BOOKING_PROCESSOR,
    _Currency,
    _Customer,
    _OverallStatus
}
