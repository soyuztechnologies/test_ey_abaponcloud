@EndUserText.label: 'My Travel processor projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZATS_AO_TRAVEL_APPROVER
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
    /* Associations */
    _Agency,
    _Booking: redirected to composition child ZATS_ao_BOOKING_APPROVER,
    _Currency,
    _Customer,
    _OverallStatus
}
