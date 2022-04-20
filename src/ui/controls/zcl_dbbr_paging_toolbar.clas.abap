"! <p class="shorttext synchronized" lang="en">Paging Toolbar</p>
CLASS zcl_dbbr_paging_toolbar DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_uitb_gui_control.

    "! <p class="shorttext synchronized" lang="en">Creates new Paging Toolbar</p>
    METHODS constructor
      IMPORTING
        io_parent   TYPE REF TO cl_gui_container
        iv_max_page TYPE i.

    METHODS update_max_page
      IMPORTING
        iv_max_page TYPE i.

    EVENTS paging
      EXPORTING VALUE(ev_current_page) TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF c_paging_function,
        previous      TYPE ui_func VALUE 'PREV',
        next          TYPE ui_func VALUE 'NEXT',
        to_first_page TYPE ui_func VALUE 'FIRST',
        go_back_5     TYPE ui_func VALUE 'BACK5',
        go_back_10    TYPE ui_func VALUE 'BACK10',
        go_back_50    TYPE ui_func VALUE 'BACK50',
        current       TYPE ui_func VALUE 'CURRENT',
        go_5_forward  TYPE ui_func VALUE 'FORWARD5',
        go_10_forward TYPE ui_func VALUE 'FORWARD10',
        go_50_forward TYPE ui_func VALUE 'FORWARD50',
        to_last_page  TYPE ui_func VALUE 'LAST',
      END OF c_paging_function.

    DATA mo_toolbar TYPE REF TO cl_gui_toolbar.
    DATA mv_current_page TYPE i.
    DATA mv_max_page TYPE i.

    METHODS update_current_page.

    METHODS update_current_page_btn.
    METHODS change_page
      IMPORTING
        iv_page_offset    TYPE i
        if_absolute_value TYPE abap_bool OPTIONAL.

    METHODS on_toolbar_click
      FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING
        fcode.

ENDCLASS.



CLASS zcl_dbbr_paging_toolbar IMPLEMENTATION.

  METHOD constructor.
    DATA(lo_paging_splitter) = NEW zcl_uitb_gui_splitter_cont(
            io_parent    = io_parent
            iv_elements  = 3
            iv_size      = |*:{ COND #( WHEN zcl_uitb_gui_helper=>is_belize_theme( ) THEN 875 ELSE 690 ) }:*|
            iv_mode      = zcl_uitb_gui_splitter_cont=>c_mode-cols
          )->set_all_sash_properties( if_visible = abap_false ).

    mo_toolbar = NEW cl_gui_toolbar(
      parent = lo_paging_splitter->get_container( 2 ) ).

    mv_current_page = 1.
    mv_max_page = iv_max_page.

    SET HANDLER on_toolbar_click FOR mo_toolbar.
    mo_toolbar->add_button_group(
      data_table = VALUE #(
        ( icon      = icon_arrow_left
          quickinfo = 'Prev. Page'
          function  = c_paging_function-previous )
        ( icon      = icon_arrow_right
          function  = c_paging_function-next
          quickinfo = 'Next Page' )
        ( butn_type = cntb_btype_sep )
        ( text      = 'First Page'
          function  = c_paging_function-to_first_page )
        ( text      = '-50'
          function  = c_paging_function-go_back_50 )
        ( text      = '-10'
          function  = c_paging_function-go_back_10 )
        ( text      = '-5'
          function  = c_paging_function-go_back_5 )
        ( text      = space
          function  = c_paging_function-current
          quickinfo = 'Set current page' )
        ( text      = '+5'
          function  = c_paging_function-go_5_forward )
        ( text      = '+10'
          function  = c_paging_function-go_10_forward )
        ( text      = '+50'
          function  = c_paging_function-go_50_forward )
        ( text      = 'Last Page'
          function  = c_paging_function-to_last_page ) ) ).

    update_current_page_btn( ).

    mo_toolbar->set_registered_events(
      events = VALUE #(
       ( eventid = cl_gui_toolbar=>m_id_function_selected ) ) ).

    cl_gui_cfw=>flush( ).
  ENDMETHOD.

  METHOD zif_uitb_gui_control~focus.
    zcl_uitb_gui_helper=>set_focus( mo_toolbar ).
  ENDMETHOD.

  METHOD zif_uitb_gui_control~has_focus.
    rf_has_focus = zcl_uitb_gui_helper=>has_focus( mo_toolbar ).
  ENDMETHOD.

  METHOD on_toolbar_click.
    CASE fcode.

      WHEN c_paging_function-previous.
        change_page( -1 ).

      WHEN c_paging_function-next.
        change_page( 1 ).

      WHEN c_paging_function-to_first_page.
        change_page(
          iv_page_offset    = 1
          if_absolute_value = abap_true ).

      WHEN c_paging_function-go_back_5.
        change_page( -5 ).

      WHEN c_paging_function-go_back_10.
        change_page( -10 ).

      WHEN c_paging_function-go_back_50.
        change_page( -50 ).

      WHEN c_paging_function-current.
        update_current_page( ).

      WHEN c_paging_function-go_5_forward.
        change_page( 5 ).

      WHEN c_paging_function-go_10_forward.
        change_page( 10 ).

      WHEN c_paging_function-go_50_forward.
        change_page( 50 ).

      WHEN c_paging_function-to_last_page.
        change_page(
          iv_page_offset    = mv_max_page
          if_absolute_value = abap_true ).

    ENDCASE.

    RAISE EVENT paging
      EXPORTING ev_current_page =  mv_current_page.

  ENDMETHOD.

  METHOD update_current_page.

    DATA(lo_popup) = zcl_uitb_pgv_factory=>create_single_field_popup(
      iv_title           = |Go to Page ({ mv_current_page NUMBER = USER } of { mv_max_page NUMBER = USER })|
      iv_validation_mode = zif_uitb_pgv_popup=>c_validation_modes-inline_user_check
      is_field           = VALUE #(
        fieldname  = 'TABIX'
        tabname    = 'SYST'
        fieldtext  = 'Page'
        field_obl  = abap_true
        value      = mv_current_page
        validation = VALUE #(
          comparator = 'BT' value_low = '1' value_high = |{ mv_max_page }| ) ) ).

    IF NOT lo_popup->show( )->cancelled( ).
      DATA(lv_value) = CONV sy-tabix( lo_popup->get_field_val_by_index( 1 ) ).
      IF lv_value <> mv_current_page.
        mv_current_page = lv_value.
        update_current_page_btn( ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD update_current_page_btn.
    mo_toolbar->set_button_info(
              EXPORTING fcode   = c_paging_function-current
                        text    = |{ mv_current_page } of { mv_max_page }|
              EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.

  METHOD change_page.
    DATA: lf_update TYPE abap_bool.

    DATA(lv_temp_page) = COND #(
      WHEN if_absolute_value = abap_true THEN iv_page_offset
      ELSE iv_page_offset + mv_current_page ).

    IF lv_temp_page < 1.
*      IF lv_temp_page > 1.
        mv_current_page = 1.
        lf_update = abap_true.
*      ENDIF.
    ELSEIF lv_temp_page > mv_max_page.
*      IF lv_temp_page < mv_max_page.
        mv_current_page = mv_max_page.
        lf_update = abap_true.
*      ENDIF.
    ELSE.
      mv_current_page = lv_temp_page.
      lf_update = abap_true.
    ENDIF.

    IF lf_update = abap_true.
      update_current_page_btn( ).
    ENDIF.
  ENDMETHOD.

  METHOD update_max_page.

    mv_max_page = iv_max_page.

  ENDMETHOD.

ENDCLASS.
