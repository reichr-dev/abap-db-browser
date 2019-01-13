LOAD-OF-PROGRAM.
  zcl_dbbr_system_helper=>set_locale_language( ).

AT SELECTION-SCREEN.
  CASE sy-dynnr.

    WHEN zif_dbbr_screen_ids=>c_show_user_settings.
      gr_user_settings_controller->zif_uitb_screen_controller~handle_user_command( CHANGING cv_function_code = sscrfields-ucomm ).

    WHEN zif_dbbr_screen_ids=>c_show_eb_settings.
      gr_eb_settings_view->pai( CHANGING cv_function_code = sscrfields-ucomm ).
  ENDCASE.

AT SELECTION-SCREEN ON EXIT-COMMAND.
  CASE sy-dynnr.

    WHEN zif_dbbr_screen_ids=>c_show_user_settings.
      gr_user_settings_controller->zif_uitb_screen_controller~cancel( ).

    WHEN zif_dbbr_screen_ids=>c_show_eb_settings.
      gr_eb_settings_view->cancel( ).
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.
  CASE sy-dynnr.

    WHEN zif_dbbr_screen_ids=>c_show_user_settings or
         zif_dbbr_screen_ids=>c_show_user_settings_general or
         zif_dbbr_screen_ids=>c_show_user_settings_favorites or
         zif_dbbr_screen_ids=>c_show_user_settings_selscreen or
         zif_dbbr_screen_ids=>c_show_user_settings_output.
*.... set button texts here because of some reason not every system
*.... returns the tab buttons from program source code analysing
      btn_intr = text-005.
      btn_fav = text-002.
      btn_alv = text-003.
      btn_sel = text-001.

      gr_user_settings_controller->zif_uitb_screen_controller~pbo( ).

    WHEN zif_dbbr_screen_ids=>c_show_eb_settings.
      gr_eb_settings_view->pbo( ).
  ENDCASE.