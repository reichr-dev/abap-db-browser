CLASS zcl_dbbr_cds_navigator DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE

  GLOBAL FRIENDS zcl_dbbr_navigator_creator .

  PUBLIC SECTION.

    INTERFACES zif_dbbr_table_navigator .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mr_source_cds_view TYPE REF TO ZCL_SAT_CDS_VIEW .
    DATA ms_tech_info TYPE zdbbr_tech_info.
    DATA mr_t_data TYPE REF TO data .
    DATA ms_association TYPE ZSAT_CDS_ASSOCIATION .
    DATA mr_tabfields TYPE REF TO zcl_dbbr_tabfield_list .
    DATA mr_source_tabfields TYPE REF TO zcl_dbbr_tabfield_list .
    DATA mt_source_index TYPE lvc_t_indx .
    DATA mv_entity_type TYPE ZSAT_ENTITY_TYPE .
    DATA mr_t_for_all_data TYPE REF TO data .
    DATA mt_nav_breadcrumbs TYPE string_table .
    DATA mv_nav_count TYPE i .
    DATA mt_param_values TYPE ZIF_SAT_TY_GLOBAL=>ty_t_cds_param_value.

    METHODS create_output_fields .
    METHODS export_data_to_memory .
    METHODS fill_selection_fields .
    METHODS constructor
      IMPORTING
        !ir_t_data           TYPE REF TO data
        is_tech_info         TYPE zdbbr_tech_info
        !ir_source_cds_view  TYPE REF TO ZCL_SAT_CDS_VIEW
        !it_source_index     TYPE lvc_t_indx
        !ir_source_tabfields TYPE REF TO zcl_dbbr_tabfield_list
        !is_association      TYPE ZSAT_CDS_ASSOCIATION
        !it_nav_breadcrumbs  TYPE string_table
        it_param_values      TYPE ZIF_SAT_TY_GLOBAL=>ty_t_cds_param_value OPTIONAL
        !iv_nav_count        TYPE i .
    METHODS handle_messages .
ENDCLASS.



CLASS zcl_dbbr_cds_navigator IMPLEMENTATION.


  METHOD constructor.
    mr_t_data          = ir_t_data.
    ms_association     = is_association.
    mt_source_index    = it_source_index.
    mr_source_cds_view = ir_source_cds_view.
    mr_source_tabfields = ir_source_tabfields.
    mt_nav_breadcrumbs = it_nav_breadcrumbs.
    mt_param_values = it_param_values.
    ms_tech_info = is_tech_info.
    mv_nav_count = iv_nav_count.
  ENDMETHOD.


  METHOD create_output_fields.
    mr_tabfields = NEW #( ).

    CASE ms_association-kind.

      WHEN ZIF_SAT_C_CDS_ASSOC_TYPE=>entity OR
           ZIF_SAT_C_CDS_ASSOC_TYPE=>table_function.

        mv_entity_type = ZIF_SAT_C_ENTITY_TYPE=>cds_view.
        TRY.
            DATA(lr_target_cds) = ZCL_SAT_CDS_VIEW_FACTORY=>read_cds_view( ms_association-ref_cds_view ).
          CATCH ZCX_SAT_DATA_READ_ERROR INTO DATA(lx_read_error).
            MESSAGE lx_read_error->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
        ENDTRY.
        DATA(ls_target_cds_header) = lr_target_cds->get_header( ).
        zcl_dbbr_cds_tabfield_util=>add_view_colums(
            ir_tabfield_list = mr_tabfields
            if_selection     = abap_false
            it_columns       = lr_target_cds->get_columns( )
            iv_name          = ms_association-ref_cds_view
            iv_raw_name      = lr_target_cds->get_header( )-entityname_raw
            iv_description   = ls_target_cds_header-description
            if_is_primary    = abap_true
        ).

      WHEN ZIF_SAT_C_CDS_ASSOC_TYPE=>table OR
           ZIF_SAT_C_CDS_ASSOC_TYPE=>view.

        mv_entity_type = ZIF_SAT_C_ENTITY_TYPE=>table.
        zcl_dbbr_tabfield_builder=>create_tabfields(
            iv_tablename        = ms_association-ref_cds_view
            ir_tabfield_list    = mr_tabfields
            if_output_active    = abap_true
            if_is_primary       = abap_true
        ).
      WHEN OTHERS.
*... TODO: raise exception???
    ENDCASE.

  ENDMETHOD.


  METHOD export_data_to_memory.
    DATA: lv_mem_id          TYPE char32.

    FIELD-SYMBOLS: <lt_for_all_data> TYPE table.

    DATA(ls_tabfield_data) = mr_tabfields->convert_to_structure( ).

    IF mt_nav_breadcrumbs IS INITIAL.
      mt_nav_breadcrumbs = VALUE #( ( mr_source_cds_view->get_header( )-entityname_raw ) ).
    ENDIF.

    mt_nav_breadcrumbs = VALUE #( BASE mt_nav_breadcrumbs
      ( |{ ms_association-ref_cds_view_raw }| )
    ).

    DATA(ls_controller_data) = VALUE zdbbr_sel_ctrl_serialized(
        entity_id              = ms_association-ref_cds_view
        entity_type            = mv_entity_type
        technical_info         = ms_tech_info
        tabfields_data         = ls_tabfield_data
        tabfields_all_data     = ls_tabfield_data
        navigation_info        = ms_association
        navigation_breadcrumbs = mt_nav_breadcrumbs
        navigation_count       = mv_nav_count + 1
    ).

    lv_mem_id = zif_dbbr_c_report_id=>main && sy-uname.

    EXPORT
      serialized = ls_controller_data
    TO MEMORY ID lv_mem_id.

*... also export for all entries selection data
    lv_mem_id = lv_mem_id && 'FORALLTAB'.
    ASSIGN mr_t_for_all_data->* TO <lt_for_all_data>.
    EXPORT
      data = <lt_for_all_data>
    TO MEMORY ID lv_mem_id.
  ENDMETHOD.


  METHOD fill_selection_fields.
    DATA: lr_s_new_line TYPE REF TO data.

    FIELD-SYMBOLS: <lt_source>       TYPE table,
                   <lt_for_all_data> TYPE table.

    ASSIGN mr_t_data->* TO <lt_source>.

*... create dynamic table to hold FOR ALL data
    mr_t_for_all_data = zcl_dbbr_ddic_util=>build_dynamic_std_table(
      VALUE #(
        FOR field IN ms_association-fields
        ( tabname   = ms_association-ref_cds_view
          fieldname = field-name )
      )
    ).

    ASSIGN mr_t_for_all_data->* TO <lt_for_all_data>.

    LOOP AT mt_source_index ASSIGNING FIELD-SYMBOL(<lv_index>).
      ASSIGN <lt_source>[ <lv_index> ] TO FIELD-SYMBOL(<ls_data>).

*... Create new line to hold data for navigation
      CREATE DATA lr_s_new_line LIKE LINE OF <lt_for_all_data>.
      ASSIGN lr_s_new_line->* TO FIELD-SYMBOL(<ls_new_line>).

      LOOP AT ms_association-fields ASSIGNING FIELD-SYMBOL(<ls_assoc_field>).

        ASSIGN COMPONENT <ls_assoc_field>-name OF STRUCTURE <ls_new_line> TO FIELD-SYMBOL(<lv_target_value>).
        CHECK sy-subrc = 0.

        ASSIGN COMPONENT <ls_assoc_field>-ref_name OF STRUCTURE <ls_data> TO FIELD-SYMBOL(<lv_ref_value>).
        IF sy-subrc = 0.
          <lv_target_value> = <lv_ref_value>.
        ELSE.
*........ Maybe this field is a literal
          IF <ls_assoc_field>-ref_name CP |'*'|.
            DATA(lv_length) = strlen( <ls_assoc_field>-ref_name ).
            <lv_target_value> = substring( val = <ls_assoc_field>-ref_name len = lv_length - 2 off = 1 ).
*........ or a preconfigured system variable
          ELSEIF <ls_assoc_field>-ref_name CP '&$SESSION.*'.
            IF <ls_assoc_field>-ref_name = '&$SESSION.SYSTEM_LANGUAGE'.
              <lv_target_value> = sy-langu.
            ELSEIF <ls_assoc_field>-ref_name = '&$SESSION.SYSTEM_DATE'.
              <lv_target_value> = sy-datum.
            ELSEIF <ls_assoc_field>-ref_name = '&$SESSION.USER'.
              <lv_target_value> = sy-uname.
            ELSEIF <ls_assoc_field>-ref_name = '&$SESSION.CLIENT'.
              <lv_target_value> = sy-mandt.
            ENDIF.
*........ or a Parameter value
          ELSEIF <ls_assoc_field>-ref_name CP '$*'.
*.......... Find the correct parameter value
            ASSIGN mt_param_values[ name = <ls_assoc_field>-ref_name+1 ] TO FIELD-SYMBOL(<ls_param_val>).
            IF sy-subrc = 0.
              <lv_target_value> = <ls_param_val>-value.
            ENDIF.
          ENDIF.
        ENDIF.

      ENDLOOP.

      <lt_for_all_data> = VALUE #( BASE <lt_for_all_data> ( <ls_new_line> ) ).

    ENDLOOP.

*... remove duplicate entries
    SORT <lt_for_all_data>.
    DELETE ADJACENT DUPLICATES FROM <lt_for_all_data> COMPARING ALL FIELDS.
  ENDMETHOD.


  METHOD handle_messages.
    DATA(lv_memid) = CONV char32( |{ zif_dbbr_c_report_id=>output }{ sy-uname }MSG| ).
    DATA: lv_message  TYPE string,
          lv_msg_type TYPE sy-msgty.

    IMPORT
      message      = lv_message
      message_type = lv_msg_type
    FROM MEMORY ID lv_memid.

    IF sy-subrc = 0 AND lv_message IS NOT INITIAL.
      FREE MEMORY ID lv_memid.
      MESSAGE lv_message TYPE lv_msg_type.
    ENDIF.
  ENDMETHOD.


  METHOD zif_dbbr_table_navigator~navigate.
*... Maximum call stack level in ABAP is 9.
*... The first and second screen of the DB Browser already raise the number to 2,
*... so there are only 7 navigations possible by using the CALL TRANSACTION solution.
*...................................................................
*... A possible work around to increase the number of possible navigations would
*... to always buffer the current information about the selection screen to memory
*... and replace the current screen information with the target entity
    IF mv_nav_count = 7.
      RAISE EXCEPTION TYPE zcx_dbbr_association_nav_error
        EXPORTING
          textid = zcx_dbbr_association_nav_error=>max_navigation_level_reached.
    ENDIF.

*... create output fields
    create_output_fields( ).

*... create selection fields
    fill_selection_fields( ).

*... fill structure for memory export and
*... export data to memory
    export_data_to_memory( ).

*... start new transaction for assocation select
    CALL TRANSACTION 'ZDBBR_START_SEL'.

*... check if there was an error message
    handle_messages( ).
  ENDMETHOD.
ENDCLASS.
