CLASS zcl_dbbr_virtual_elem_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! <p class="shorttext synchronized" lang="en">Determine fields needed for virtual element calculation</p>
    "!
    "! @parameter it_fields | <p class="shorttext synchronized" lang="en">Field list</p>
    "! @parameter io_cds_view | <p class="shorttext synchronized" lang="en">CDS view name</p>
    "! @parameter rt_requested_elements | <p class="shorttext synchronized" lang="en">List of requested elements</p>
    METHODS determine_requested_elements
      IMPORTING
        io_cds_view                  TYPE REF TO zcl_sat_cds_view
        it_fields                    TYPE zdbbr_tabfield_info_ui_itab
      RETURNING
        VALUE(rt_requested_elements) TYPE stringtab.

    "! <p class="shorttext synchronized" lang="en">Determine if virtual element calculation is needed</p>
    "!
    "! @parameter iv_entity_name | <p class="shorttext synchronized" lang="en">CDS view name</p>
    "! @parameter it_fields | <p class="shorttext synchronized" lang="en">Field list</p>
    "! @raising zcx_dbbr_application_exc | <p class="shorttext synchronized" lang="en">DB browser exception</p>
    METHODS adjust_requested
      IMPORTING
        iv_entity_name TYPE zsat_cds_view_name
        it_fields      TYPE zdbbr_tabfield_info_ui_itab
      RAISING
        zcx_dbbr_application_exc.

    "! <p class="shorttext synchronized" lang="en">Calculate virtual elements</p>
    "!
    "! @parameter iv_entity_name | <p class="shorttext synchronized" lang="en">CDS view name</p>
    "! @parameter ct_data | <p class="shorttext synchronized" lang="en">List of data </p>
    "! @raising zcx_dbbr_application_exc | <p class="shorttext synchronized" lang="en">DB browser exception</p>
    METHODS calculate_elements
      IMPORTING
        iv_entity_name TYPE zsat_cds_view_name
      CHANGING
        ct_data        TYPE REF TO data
      RAISING
        zcx_dbbr_application_exc.

    METHODS filter_element
      IMPORTING
        io_cds_view          TYPE REF TO zcl_sat_cds_view
        io_tabfields         TYPE REF TO zcl_dbbr_tabfield_list
        iv_element           TYPE sadl_entity_element
        iv_operator          TYPE string
        iv_value             TYPE string
      RETURNING
        VALUE(rv_where_cond) TYPE string .

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES ty_t_sorted_string TYPE SORTED TABLE OF string WITH UNIQUE DEFAULT KEY.

    CONSTANTS:
      BEGIN OF c_annotation_objectmodel,
        virtual_elem_calc_by   TYPE string VALUE 'OBJECTMODEL.VIRTUALELEMENTCALCULATEDBY',
        virtual_elem_filter_by TYPE string VALUE 'OBJECTMODEL.FILTER.TRANSFORMEDBY',
      END OF c_annotation_objectmodel,
      c_meth_get_calculation_info TYPE string VALUE 'IF_SADL_EXIT_CALC_ELEMENT_READ~GET_CALCULATION_INFO',
      c_meth_map_atom             TYPE string VALUE 'IF_SADL_EXIT_FILTER_TRANSFORM~MAP_ATOM'.

    DATA mo_sadl_exit_handler TYPE REF TO lcl_sadl_exit_handler.

    "! <p class="shorttext synchronized" lang="en">Get sadl exit handler instance</p>
    "!
    "! @parameter iv_entity_name | <p class="shorttext synchronized" lang="en">CDS view name</p>
    "! @parameter ro_sadl_exit_handler | <p class="shorttext synchronized" lang="en">Reference to SADL exit handler</p>
    METHODS get_sadl_exit_handler
      IMPORTING
        iv_entity_name              TYPE zsat_cds_view_name
      RETURNING
        VALUE(ro_sadl_exit_handler) TYPE REF TO lcl_sadl_exit_handler.

ENDCLASS.

CLASS zcl_dbbr_virtual_elem_handler IMPLEMENTATION.

  METHOD get_sadl_exit_handler.
    IF mo_sadl_exit_handler IS INITIAL.
      mo_sadl_exit_handler = NEW #( iv_entity_name ).
    ENDIF.
    ro_sadl_exit_handler = mo_sadl_exit_handler.
  ENDMETHOD.

  METHOD determine_requested_elements.

    DATA: lt_exit_class         TYPE TABLE OF classname,
          lo_exit_class         TYPE REF TO object,
          lt_requested_elements TYPE ty_t_sorted_string.

    DATA(lt_annotation) = io_cds_view->get_annotations(
      it_annotation_name = VALUE #( ( sign = 'I' option = 'EQ' low = c_annotation_objectmodel-virtual_elem_calc_by ) ) ).

    LOOP AT lt_annotation ASSIGNING FIELD-SYMBOL(<ls_annotation>).
      IF line_exists( it_fields[ fieldname = <ls_annotation>-fieldname ] ).
        lt_exit_class = VALUE #( BASE lt_exit_class ( CONV #( <ls_annotation>-value+5 ) ) ).
      ENDIF.
    ENDLOOP.

    SORT lt_exit_class.
    DELETE ADJACENT DUPLICATES FROM lt_exit_class.

    DATA(lt_calc_elements) = VALUE ty_t_sorted_string(
      FOR ls_field IN it_fields WHERE ( is_text_field = abap_false ) ( CONV #( ls_field-fieldname ) ) ).

    LOOP AT lt_exit_class ASSIGNING FIELD-SYMBOL(<lv_exit_class>).

      TRY.
          CREATE OBJECT lo_exit_class TYPE (<lv_exit_class>).

          CALL METHOD lo_exit_class->(c_meth_get_calculation_info)
            EXPORTING
              it_requested_calc_elements = lt_calc_elements
              iv_entity                  = CONV string( io_cds_view->mv_view_name )
            IMPORTING
              et_requested_orig_elements = lt_requested_elements.
        CATCH cx_sy_create_object_error
              cx_sy_ref_is_initial
              cx_sy_dyn_call_error.
      ENDTRY.

      rt_requested_elements = VALUE #( BASE rt_requested_elements ( LINES OF lt_requested_elements ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD calculate_elements.

    get_sadl_exit_handler( iv_entity_name )->calculate_elements( CHANGING ct_data = ct_data ).

  ENDMETHOD.

  METHOD adjust_requested.

    DATA(lt_requested) = VALUE stringtab( FOR ls_field IN it_fields ( CONV #( ls_field-fieldname ) ) ).
    get_sadl_exit_handler( iv_entity_name )->adjust_requested( CHANGING ct_requested_element = lt_requested ).

  ENDMETHOD.

  METHOD filter_element.

*    DATA mo_osql TYPE REF TO cl_sadl_sql_statement.
*    DATA mo_builder TYPE REF TO cl_sadl_sql_builder.
*    DATA mo_dyn_sql_builder TYPE REF TO cl_sadl_sql_builder.
*
*    DATA lo_sql_statement TYPE REF TO cl_sadl_sql_statement.
*    lo_sql_statement = cl_sadl_sql_statement=>create( ).
*    mo_osql = lo_sql_statement.
*
*    mo_builder = lo_sql_statement->get_dyn_sql_builder( ).
*
*    mo_osql->select( )->element( `S1` )->as( `T1` )->from( )->entity( `SFLIGHT`
*                     )->where( )->compare_element_to_value( iv_element = 'S1' iv_low = 'XX' iv_operator = if_sadl_sql=>co_operator-eq ).
*    mo_builder->get_sections_for_select( RECEIVING rs_dyn_sql_clauses = DATA(ls_parts) ).
*
*    cl_abap_unit_assert=>assert_equals( act = ls_parts-where  exp = `S1 = 'XX'` ).
    IF sy-uname = 'REICHR'.
      DATA: lo_exit_class TYPE REF TO object,
            lo_condition  TYPE REF TO if_sadl_cond_provider_generic.

      DATA(lt_annotation) = io_cds_view->get_annotations(
         it_annotation_name = VALUE #( ( sign = 'I' option = 'EQ' low = c_annotation_objectmodel-virtual_elem_filter_by ) ) ).

      DATA(lv_exit_class) =  lt_annotation[ fieldname = iv_element ]-value+5.

      TRY.
          CREATE OBJECT lo_exit_class TYPE (lv_exit_class).

          CALL METHOD lo_exit_class->(c_meth_map_atom)
            EXPORTING
              iv_entity    = CONV string( io_cds_view->mv_view_name )
              iv_element   = iv_element
              iv_operator  = iv_operator
              iv_value     = iv_value
            RECEIVING
              ro_condition = lo_condition.

        CATCH cx_sy_create_object_error
              cx_sy_ref_is_initial
              cx_sy_dyn_call_error.
      ENDTRY.

      lo_condition->if_sadl_condition_provider~get_condition( IMPORTING et_sadl_condition = DATA(lt_condition) ).

      DATA lo_engine TYPE REF TO lcl_engine. "cl_sadl_query_engine_osql.
      DATA lo_sql TYPE REF TO cl_sadl_sql_statement.

      lo_engine = NEW lcl_engine( ).
      lo_sql = cl_sadl_sql_statement=>create( ).

      DATA lt_elements TYPE if_sadl_view_db=>tt_elements.
      DATA(lt_fields) = io_tabfields->get_fields( ).

      LOOP AT lt_condition ASSIGNING FIELD-SYMBOL(<ls_condition>) WHERE attribute IS NOT INITIAL.

*        IF NOT line_exists( lt_elements[ alias = <ls_condition>-attribute ] ).

        lt_elements = VALUE #( BASE lt_elements (
          entity_alias = io_cds_view->mv_view_name
*            alias = lt_fields[ fieldname = <ls_condition>-attribute ]-fieldname
          alias = <ls_condition>-attribute
          db_column_name = <ls_condition>-attribute ) ).

*        ENDIF.

      ENDLOOP.

      lo_engine->if_sadl_query_engine~set_view_metadata(
        is_view_metadata = VALUE #( entities = VALUE #( ( db_artifact = '/DRY/C_DELIVERYINFORMATIONTP' is_anchor = 'X' )
                                                        ( db_artifact = '/DRY/C_DELIVERYMATERIALTP' alias = '_Material' ) )
                                    elements = lt_elements ) ).
      lo_engine->create_where_clause( it_sadl_conditions = lt_condition
                                        io_sql = lo_sql ).

      rv_where_cond = lo_sql->as_string( ).

      DATA(lt_requested) = VALUE stringtab( FOR ls_field IN lt_fields ( CONV #( ls_field-fieldname ) ) ).

      lo_engine->if_sadl_query_engine~select( EXPORTING is_restrictions = VALUE #( " text_search         = is_text_search
                                                                    complex_condition   = lt_condition
                                                                  "  value_set_condition = ls_value_set_condition
                                                                  "  having_condition    = it_having_condition
                                                                   )
*                                       is_aggregation     = is_aggregation
*                                       it_sort_elements   = lt_sort_elements
                                      is_requested       = VALUE #( elements = lt_requested
                                                                    fill_data = abap_true
                                                                    fill_number_all_hits = abap_true )
*                                       is_paging          = ls_paging
*                                       is_parameters      = ls_parameters
*                                       iv_disable_locale  = is_select_control-disable_locale
                            IMPORTING ev_number_all_hits = DATA(ev_number_all_hits) ).
*                                       et_flat_data       = et_data_rows) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
