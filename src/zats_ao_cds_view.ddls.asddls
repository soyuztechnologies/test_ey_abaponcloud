@AbapCatalog.sqlViewName: 'ZATSAOCDSVIEW'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Old approach of CDS views'
define view ZATS_AO_CDS_VIEW as select from zats_ao_bpa
{
    key bp_id as BpId,
    bp_role as BpRole,
    company_name as CompanyName,
    street as Street,
    country as Country,
    region as Region,
    city as City
}
