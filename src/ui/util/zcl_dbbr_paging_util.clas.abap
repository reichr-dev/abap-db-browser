"! <p class="shorttext synchronized" lang="en">Paging Util</p>
CLASS zcl_dbbr_paging_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC

  GLOBAL FRIENDS zcl_dbbr_selection_util.

  PUBLIC SECTION.

    METHODS:
      constructor
        IMPORTING
          io_selection_util TYPE REF TO zcl_dbbr_selection_util
          io_alv_grid       TYPE REF TO zcl_dbbr_output_grid OPTIONAL,

      create_paging_toolbar
        IMPORTING
          io_parent                TYPE REF TO cl_gui_container
          iv_max_page              TYPE i
        RETURNING
          VALUE(ro_paging_toolbar) TYPE REF TO zcl_dbbr_paging_toolbar.

    EVENTS refresh_page.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
      mo_paging_toolbar  TYPE REF TO zcl_dbbr_paging_toolbar,
      mo_selection_lines TYPE REF TO zif_dbbr_selection_lines.

    METHODS:
      on_paging
        FOR EVENT paging OF zcl_dbbr_paging_toolbar
        IMPORTING
          ev_current_page.
ENDCLASS.



CLASS zcl_dbbr_paging_util IMPLEMENTATION.

  METHOD constructor.
    mo_selection_lines = io_selection_util.
  ENDMETHOD.


  METHOD create_paging_toolbar.

    IF mo_paging_toolbar IS INITIAL.
      mo_paging_toolbar = NEW #(
        io_parent   = io_parent
        iv_max_page = iv_max_page ).
    ENDIF.

    ro_paging_toolbar = mo_paging_toolbar.
    SET HANDLER on_paging FOR mo_paging_toolbar.

  ENDMETHOD.


  METHOD on_paging.

    mo_selection_lines->update_offset( ev_current_page ).
    mo_paging_toolbar->update_max_page( mo_selection_lines->get_max_lines_existing( ) / mo_selection_lines->get_max_lines( ) + 1 ).

    RAISE EVENT refresh_page.

    cl_gui_cfw=>set_new_ok_code( 'DUMMY' ). "force pbo/pai call to update the status

  ENDMETHOD.

ENDCLASS.
