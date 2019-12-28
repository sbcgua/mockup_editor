**********************************************************************
* this is heavily based on ZEVOLVING code
* http://zevolving.com/2015/06/salv-table-21-editable-with-single-custom-method/
**********************************************************************

class lcl_salv_model_list definition inheriting from cl_salv_model_base.
  public section.
    class-methods:
      get_grid
        importing
          io_salv_model type ref to cl_salv_model
        returning
          value(ro_gui_alv_grid) type ref to cl_gui_alv_grid
        raising
          cx_salv_msg.
endclass.

class lcl_salv_model_list implementation.
  method get_grid.
    data:
     lo_grid_adap type ref to cl_salv_grid_adapter,
     lo_fs_adap   type ref to cl_salv_fullscreen_adapter,
     lo_root      type ref to cx_root.

    try.
      lo_grid_adap ?= io_salv_model->r_controller->r_adapter.
    catch cx_root into lo_root.
      try. "could be fullscreen adaptper
        lo_fs_adap ?= io_salv_model->r_controller->r_adapter.
      catch cx_root into lo_root.
        raise exception type cx_salv_msg
          exporting
            previous = lo_root
            msgid    = '00'
            msgno    = '001'
            msgty    = 'E'
            msgv1    = 'Check PREVIOUS exception'.
      endtry.
    endtry.

    if lo_grid_adap is not initial.
      ro_gui_alv_grid = lo_grid_adap->get_grid( ).
    elseif lo_fs_adap is not initial.
      ro_gui_alv_grid = lo_fs_adap->get_grid( ).
    else.
      raise exception type cx_salv_msg
        exporting
          msgid = '00'
          msgno = '001'
          msgty = 'W'
          msgv1 = 'Adapter is not bound yet'.
    endif.
  endmethod.

endclass.

class lcl_salv_edit_enabler definition final.

  public section.
    class-methods toggle_editable
      importing
        io_salv type ref to cl_salv_table.
    class-methods get_grid
      importing
        io_salv_model type ref to cl_salv_model
      returning
        value(ro_grid) type ref to cl_gui_alv_grid
      raising
        cx_salv_error.

    data t_salv type standard table of ref to cl_salv_table.

    methods:
      on_after_refresh
        for event after_refresh of cl_gui_alv_grid
        importing sender,
      on_toolbar
        for event toolbar of cl_gui_alv_grid
        importing e_object e_interactive sender.

  private section.
    class-data o_event_h type ref to object.

endclass.

CLASS lcl_salv_edit_enabler IMPLEMENTATION.

  method get_grid.
    data lo_error type ref to cx_salv_msg.
    if io_salv_model->model ne if_salv_c_model=>table.
      raise exception type cx_salv_msg
        exporting
          msgid = '00'
          msgno = '001'
          msgty = 'E'
          msgv1 = 'Incorrect SALV Type'.
    endif.
    ro_grid = lcl_salv_model_list=>get_grid( io_salv_model ).
  endmethod.                    "GET_GRID

  method toggle_editable.
    data lo_event_h type ref to lcl_salv_edit_enabler.

    "event handler
    if lcl_salv_edit_enabler=>o_event_h is not bound.
      create object lcl_salv_edit_enabler=>o_event_h type lcl_salv_edit_enabler.
    endif.

    lo_event_h ?= lcl_salv_edit_enabler=>o_event_h.
    append io_salv to lo_event_h->t_salv.

    set handler lo_event_h->on_after_refresh
      for all instances
      activation 'X'.
    set handler lo_event_h->on_toolbar
      for all instances
      activation 'X'.
  endmethod.                    "set_editable

  method on_after_refresh.
    data lo_grid   type ref to cl_gui_alv_grid.
    data ls_layout type lvc_s_layo.
    data lo_salv   type ref to cl_salv_table.

    try.
      loop at t_salv into lo_salv.
        lo_grid = lcl_salv_edit_enabler=>get_grid( lo_salv ).
        check lo_grid eq sender.
        " deregister the event handler
        set handler me->on_after_refresh
          for all instances
          activation space.

        " toggle editable
        ls_layout-edit = boolc( ls_layout-edit = abap_false ).
        lo_grid->set_frontend_layout( ls_layout ).
        if ls_layout-edit = abap_true.
          lo_grid->set_ready_for_input( 1 ).
        else.
          lo_grid->set_ready_for_input( 0 ).
        endif.
      endloop.
    catch cx_salv_error.
    endtry.
  endmethod.

  " TODO REFACTOR !!!
  method on_toolbar.

    data lo_grid    type ref to cl_gui_alv_grid.
    data ls_layout  type lvc_s_layo.
    data mt_toolbar type ttb_button.
    data ls_toolbar like line of mt_toolbar.
    data lo_salv    type ref to cl_salv_table.

    try.
      loop at t_salv into lo_salv.
        lo_grid = lcl_salv_edit_enabler=>get_grid( lo_salv ).
        if lo_grid eq sender.
          exit.
        else.
          clear lo_grid.
        endif.
      endloop.
    catch cx_salv_msg.
      exit.
    endtry.

    check lo_grid is bound.
    check lo_grid->is_ready_for_input( ) = 1.

* … toolbar button check
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_check.
    ls_toolbar-quickinfo  = text-053.  "eingaben prfen
    ls_toolbar-icon        = icon_check.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar seperator
    clear ls_toolbar.
    ls_toolbar-function    = '&&sep01'.
    ls_toolbar-butn_type  = 3.
    append ls_toolbar to mt_toolbar.

* … toolbar button cut
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_cut.
    ls_toolbar-quickinfo  = text-046.  "ausschneiden
    ls_toolbar-icon        = icon_system_cut.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar button copy
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_copy.
    ls_toolbar-quickinfo  = text-045.                        " kopieren
    ls_toolbar-icon        = icon_system_copy.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar button paste over row
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_paste.
    ls_toolbar-quickinfo  = text-047.
    ls_toolbar-icon        = icon_system_paste.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar button paste new row
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_paste_new_row.
    ls_toolbar-quickinfo  = text-063.
    ls_toolbar-icon        = icon_system_paste.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar button undo
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_undo.
    ls_toolbar-quickinfo  = text-052.  "rckgngig
    ls_toolbar-icon        = icon_system_undo.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar separator
    clear ls_toolbar.
    ls_toolbar-function    = '&&sep02'.
    ls_toolbar-butn_type  = 3.
    append ls_toolbar to mt_toolbar.

* … toolbar button append row
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_append_row.
    ls_toolbar-quickinfo   = text-054.  "zeile anhngen
    ls_toolbar-icon        = icon_create.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar button insert row
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_insert_row.
    ls_toolbar-quickinfo  = text-048.  "zeile einfgen
    ls_toolbar-icon        = icon_insert_row.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar button delete row
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_delete_row.
    ls_toolbar-quickinfo  = text-049.  "zeile lschen
    ls_toolbar-icon        = icon_delete_row.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar button copy row
    clear ls_toolbar.
    ls_toolbar-function    = cl_gui_alv_grid=>mc_fc_loc_copy_row.
    ls_toolbar-quickinfo  = text-051.  "duplizieren
    ls_toolbar-icon        = icon_copy_object.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

    clear ls_toolbar.
    ls_toolbar-function    = 'UMMM'.
    ls_toolbar-quickinfo  = 'UMMM'.
    ls_toolbar-icon        = icon_copy_object.
    ls_toolbar-disabled    = space.
    append ls_toolbar to mt_toolbar.

* … toolbar separator
    clear ls_toolbar.
    ls_toolbar-function    = '&sep03'.
    ls_toolbar-butn_type  = 3.
    append ls_toolbar to mt_toolbar.

    append lines of mt_toolbar to e_object->mt_toolbar.

  endmethod.

endclass.
