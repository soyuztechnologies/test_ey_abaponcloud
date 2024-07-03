@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Fact data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_ATS_AO_SALES as select from zats_ao_so_hdr  as hdr
association[1..*] to zats_ao_so_item as _Items on
$projection.OrderId = _Items.order_id
{
    key hdr.order_id as OrderId,
    hdr.order_no as OrderNo,
    hdr.buyer as Buyer,
    hdr.created_by as CreatedBy,
    hdr.created_on as CreatedOn,
    --exposed association
    _Items    
}
