@EndUserText.label: 'My Travel processor projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZATS_AO_BOOKSUPPL_PROCESSOR 
    as projection on ZATS_AO_BOOKSUPPL
{
    key TravelId,
    key BookingId,
    key BookingSupplementId,
    SupplementId,
    Price,
    CurrencyCode,
    LastChangedAt,
    /* Associations */
    _Booking: redirected to parent ZATS_AO_BOOKING_PROCESSOR,
    _Travel: redirected to ZATS_AO_TRAVEL_PROCESSOR
}
