INTERFACE zif_dbbr_selection_lines
  PUBLIC.

  METHODS:
    get_max_lines_existing
      RETURNING
        VALUE(rv_max_lines_existing) TYPE zdbbr_no_of_lines,

    update_offset
      IMPORTING
        iv_page TYPE i,

    get_max_lines
      RETURNING
        VALUE(rv_max_lines) TYPE zdbbr_no_of_lines.
ENDINTERFACE.
