@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Analytics Consumption view'
@Metadata.ignorePropagatedAnnotations: false
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Analytics.query: true
define view entity ZC_ATS_AO_SALES_ANA as select from ZI_ATS_AO_SALES_CUBE
{
    key _BusinessPartner.CompanyName,
    key _BusinessPartner.CountryName,
    GrossAmount,
    CurrencyCode,
    Quantity,
    UnitOfMeasure
}
