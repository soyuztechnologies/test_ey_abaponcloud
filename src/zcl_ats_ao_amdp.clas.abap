CLASS zcl_ats_ao_amdp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_amdp_marker_hdb .
    INTERFACES if_oo_adt_classrun .

    CLASS-METHODS add_numbers IMPORTING value(a) TYPE i
                                        value(b) type i
                              EXPORTING
                                        value(result) TYPE i.

    CLASS-METHODS get_customer_by_id IMPORTING
                                        value(i_bp_id) TYPE zats_ao_dte_id
                                     EXPORTING
                                        VALUE(e_res) TYPE char40.

    CLASS-METHODS get_product_mrp IMPORTING
                                    VALUE(i_tax) type i
                                  EXPORTING
                                    VALUE(otab) type zats_ao_tt_product_mrp.

    CLASS-METHODS get_total_sales for table FUNCTION ZATS_AO_TF.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ats_ao_amdp IMPLEMENTATION.

  METHOD get_total_sales by DATABASE FUNCTION FOR HDB LANGUAGE SQLSCRIPT
                        OPTIONS READ-ONLY
                        USING zats_ao_bpa zats_ao_so_hdr zats_ao_so_item
  .

    return select
            bpa.client,
            bpa.company_name,
            sum( item.amount ) as total_sales,
            item.currency as currency_code,
            RANK ( ) OVER ( order by sum( item.amount ) desc ) as customer_rank
     from zats_ao_bpa as bpa
    INNER join zats_ao_so_hdr as sls
    on bpa.bp_id = sls.buyer
    inner join zats_ao_so_item as item
    on sls.order_id = item.order_id
    group by bpa.client,
            bpa.company_name,
            item.currency ;

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

     zcl_ats_ao_amdp=>get_product_mrp(
       EXPORTING
         i_tax = 18
       IMPORTING
         otab  = data(itab)
     ).

     out->write(
      EXPORTING
        data   = itab
    ).


*    zcl_ats_ao_amdp=>get_customer_by_id(
*      EXPORTING
*        i_bp_id = '067AA621F9F71EEF8BA638273A8ED9AB'
*      IMPORTING
*        e_res   = data(lv_res)
*    ).
*    out->write(
*      EXPORTING
*        data   = |The result of AMDP Execution is ---> { lv_res }|
*    ).


*    zcl_ats_ao_amdp=>add_numbers(
*      EXPORTING
*        a      = 10
*        b      = 20
*      IMPORTING
*        result = data(lv_res)
*    ).
*
*    out->write(
*      EXPORTING
*        data   = |The result of AMDP Execution is ---> { lv_res }|
*    ).


  ENDMETHOD.

  METHOD add_numbers by DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
  OPTIONS READ-ONLY.
    DECLARE x integer;
    DECLARE y INTEGER;

    x := a;
    y := b;

    result := :x + :y;

  ENDMETHOD.

  METHOD get_customer_by_id BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                            options read-only
                            USING zats_ao_bpa .

    select company_name into e_res from zats_ao_bpa where bp_id = :i_bp_id;

  ENDMETHOD.

  METHOD get_product_mrp BY DATABASE PROCEDURE FOR HDB LANGUAGE SQLSCRIPT
                            options read-only
                            USING zats_ao_product.
*   declare variables
    declare lv_Count integer;
    declare i integer;
    declare lv_mrp bigint;
    declare lv_price_d integer;

*   get all the products in a implicit table (like a internal table in abap)
    lt_prod = select * from zats_ao_product;

*   get the record count of the table records
    lv_count := record_count( :lt_prod );

*   loop at each record one by one and calculate the price after discount (dbtable)
    for i in 1..:lv_count do
*   calculate the MRP based on input tax
        lv_price_d := :lt_prod.price[i] * ( 100 - :lt_prod.discount[i] ) / 100;
        lv_mrp := :lv_price_d * ( 100 + :i_tax ) / 100;
*   if the MRP is more than 15k, an additional 10% discount to be applied
        if lv_mrp > 15000 then
            lv_mrp := :lv_mrp * 0.90;
        END IF ;
*   fill the otab for result (like in abap we fill another internal table with data)
        :otab.insert( (
                          :lt_prod.name[i],
                          :lt_prod.category[i],
                          :lt_prod.price[i],
                          :lt_prod.currency[i],
                          :lt_prod.discount[i],
                          :lv_price_d,
                          :lv_mrp
                      ), i );
    END FOR ;

  ENDMETHOD.

ENDCLASS.
