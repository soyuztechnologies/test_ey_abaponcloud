@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Composite, Cube view for sales data'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Analytics.dataCategory: #CUBE
define view entity ZI_ATS_AO_SALES_CUBE as select from ZI_ATS_AO_SALES
association[1] to ZI_ATS_AO_BPA as _BusinessPartner on
$projection.Buyer = _BusinessPartner.BpId
association[1] to ZI_ATS_AO_PRODUCT as _Product on 
$projection.Product = _Product.ProductId
{
    key ZI_ATS_AO_SALES.OrderId,
    key ZI_ATS_AO_SALES._Items.item_id as ItemId,
    ZI_ATS_AO_SALES.OrderNo,
    ZI_ATS_AO_SALES.Buyer,
    ZI_ATS_AO_SALES.CreatedBy,
    ZI_ATS_AO_SALES.CreatedOn,
    /* Associations */
    ZI_ATS_AO_SALES._Items.product as Product,
    @DefaultAggregation: #SUM
    @Semantics.amount.currencyCode: 'CurrencyCode'
    ZI_ATS_AO_SALES._Items.amount as GrossAmount,
    ZI_ATS_AO_SALES._Items.currency as CurrencyCode,
    @DefaultAggregation: #SUM
    @Semantics.quantity.unitOfMeasure: 'UnitOfMeasure'
    ZI_ATS_AO_SALES._Items.qty as Quantity,
    ZI_ATS_AO_SALES._Items.uom as UnitOfMeasure,
    _Product,
    _BusinessPartner
}
