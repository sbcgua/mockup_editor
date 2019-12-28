class ZCX_W3MIME_ERROR definition
*  public
  inheriting from CX_STATIC_CHECK
  final
  create public .

  public section.

    interfaces IF_T100_MESSAGE .

    constants:
      begin of ZCX_W3MIME_ERROR,
        msgid type symsgid value 'SY',
        msgno type symsgno value '499',
        attr1 type scx_attrname value 'MSG',
        attr2 type scx_attrname value '',
        attr3 type scx_attrname value '',
        attr4 type scx_attrname value '',
      end of ZCX_W3MIME_ERROR .
    data MSG type STRING read-only .

    methods CONSTRUCTOR
      importing
        !TEXTID like IF_T100_MESSAGE=>T100KEY optional
        !PREVIOUS like PREVIOUS optional
        !MSG type STRING optional .
    class-methods RAISE
      importing
        !MSG type STRING
      raising
        ZCX_W3MIME_ERROR .
  protected section.
  private section.
ENDCLASS.



CLASS ZCX_W3MIME_ERROR IMPLEMENTATION.


  method CONSTRUCTOR.
    SUPER->CONSTRUCTOR( PREVIOUS = PREVIOUS ).
    me->MSG = MSG .
    clear me->textid.
    if textid is initial.
      IF_T100_MESSAGE~T100KEY = ZCX_W3MIME_ERROR .
    else.
      IF_T100_MESSAGE~T100KEY = TEXTID.
    endif.
  endmethod.


  method raise.
    raise exception type zcx_w3mime_error
      exporting
        textid = zcx_w3mime_error
        msg    = msg.
  endmethod.
ENDCLASS.

class ZCL_W3MIME_STORAGE definition
*  public
  final
  create public .

  public section.

    class-methods CHECK_OBJ_EXISTS
      importing
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
      returning
        value(RV_YES) type ABAP_BOOL .
    class-methods READ_OBJECT
      importing
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
      exporting
        !ET_DATA type LVC_T_MIME
        !EV_SIZE type I
      raising
        ZCX_W3MIME_ERROR .
    class-methods UPDATE_OBJECT
      importing
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
        !IT_DATA type LVC_T_MIME
        !IV_SIZE type I
      raising
        ZCX_W3MIME_ERROR .
    class-methods GET_OBJECT_INFO
      importing
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
      returning
        value(RS_OBJECT) type WWWDATATAB
      raising
        ZCX_W3MIME_ERROR .
    class-methods READ_OBJECT_X
      importing
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
      returning
        value(RV_DATA) type XSTRING
      raising
        ZCX_W3MIME_ERROR .
    class-methods UPDATE_OBJECT_X
      importing
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
        !IV_DATA type XSTRING
      raising
        ZCX_W3MIME_ERROR .
    class-methods CHOOSE_MIME_DIALOG
      returning
        value(RV_OBJ_NAME) type SHVALUE_D .
    class-methods READ_OBJECT_SINGLE_META
      importing
        !IV_PARAM type W3_NAME
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
      returning
        value(RV_VALUE) type W3_QVALUE
      raising
        ZCX_W3MIME_ERROR .
    class-methods UPDATE_OBJECT_META
      importing
        !IV_FILENAME type W3_QVALUE optional
        !IV_EXTENSION type W3_QVALUE optional
        !IV_MIME_TYPE type W3_QVALUE optional
        !IV_VERSION type W3_QVALUE optional
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
      raising
        ZCX_W3MIME_ERROR .
    class-methods UPDATE_OBJECT_SINGLE_META
      importing
        !IV_PARAM type W3_NAME
        !IV_VALUE type W3_QVALUE
        !IV_KEY type WWWDATA-OBJID
        !IV_TYPE type WWWDATA-RELID default 'MI'
      raising
        ZCX_W3MIME_ERROR .
  protected section.
  private section.
ENDCLASS.



CLASS ZCL_W3MIME_STORAGE IMPLEMENTATION.


  method check_obj_exists.

    data dummy type wwwdata-relid.

    select single relid into dummy
      from wwwdata
      where relid = iv_type
      and   objid = iv_key
      and   srtf2 = 0.

    rv_yes = boolc( sy-subrc = 0 ).

  endmethod.  " check_obj_exists.


  method choose_mime_dialog.

    types:
      begin of t_w3head,
        objid type wwwdata-objid,
        text  type wwwdata-text,
      end of t_w3head.

    data:
          ls_return type ddshretval,
          lt_data   type standard table of t_w3head,
          lt_return type standard table of ddshretval.

    select distinct objid text from wwwdata
      into corresponding fields of table lt_data
      where relid = 'MI'
      and   objid like 'Z%'
      order by objid.

    call function 'F4IF_INT_TABLE_VALUE_REQUEST'
      exporting
        retfield        = 'OBJID'
        value_org       = 'S'
      tables
        value_tab       = lt_data
        return_tab      = lt_return
      exceptions
        parameter_error = 1
        no_values_found = 2
        others          = 3.

    if sy-subrc is not initial.
      return. " Empty value
    endif.

    read table lt_return into ls_return index 1. " fail is ok => empty return
    rv_obj_name = ls_return-fieldval.

  endmethod.


  method get_object_info.

    select single * into corresponding fields of rs_object
      from wwwdata
      where relid = iv_type
      and   objid = iv_key
      and   srtf2 = 0.

    if sy-subrc > 0.
      zcx_w3mime_error=>raise( 'Cannot read W3xx info' ). "#EC NOTEXT
    endif.

  endmethod.  " get_object_info.


  method read_object.

    data: lv_value  type w3_qvalue,
          ls_object type wwwdatatab.

    clear: et_data, ev_size.

    call function 'WWWPARAMS_READ'
      exporting
        relid = iv_type
        objid = iv_key
        name  = 'filesize'
      importing
        value = lv_value
      exceptions
        others = 1.

    if sy-subrc > 0.
      zcx_w3mime_error=>raise( 'Cannot read W3xx filesize parameter' ). "#EC NOTEXT
    endif.

    ev_size         = lv_value.
    ls_object-relid = iv_type.
    ls_object-objid = iv_key.

    call function 'WWWDATA_IMPORT'
      exporting
        key               = ls_object
      tables
        mime              = et_data
      exceptions
        wrong_object_type = 1
        import_error      = 2.

    if sy-subrc > 0.
      zcx_w3mime_error=>raise( 'Cannot upload W3xx data' ). "#EC NOTEXT
    endif.

  endmethod.  " read_object.


  method READ_OBJECT_SINGLE_META.

    assert iv_type = 'MI' or iv_type = 'HT'.

    call function 'WWWPARAMS_READ'
      exporting
        relid = iv_type
        objid = iv_key
        name  = iv_param
      importing
        value = rv_value
      exceptions
        others = 1.

    if sy-subrc > 0.
      zcx_w3mime_error=>raise( |Cannot read W3xx metadata: { iv_param }| ). "#EC NOTEXT
    endif.

  endmethod.


  method read_object_x.
    data:
          lt_data type lvc_t_mime,
          lv_size type i.

    read_object(
      exporting
        iv_key  = iv_key
        iv_type = iv_type
      importing
        et_data = lt_data
        ev_size = lv_size ).

    call function 'SCMS_BINARY_TO_XSTRING'
      exporting
        input_length = lv_size
      importing
        buffer       = rv_data
      tables
        binary_tab   = lt_data.

  endmethod.  " read_object_x.


  method update_object.

    data: lv_temp   type wwwparams-value,
          ls_object type wwwdatatab.

    " update file size
    lv_temp = iv_size.
    condense lv_temp.
    update_object_single_meta(
      iv_type  = iv_type
      iv_key   = iv_key
      iv_param = 'filesize'
      iv_value = lv_temp ).

    " update version
    try .
      lv_temp = read_object_single_meta(
        iv_type  = iv_type
        iv_key   = iv_key
        iv_param = 'version' ).

      if lv_temp is not initial and strlen( lv_temp ) = 5 and lv_temp+0(5) co '1234567890'.
        data lv_version type numc_5.
        lv_version = lv_temp.
        lv_version = lv_version + 1.
        lv_temp    = lv_version.
        update_object_single_meta(
          iv_type  = iv_type
          iv_key   = iv_key
          iv_param = 'version'
          iv_value = lv_temp ).
      endif.

    catch zcx_w3mime_error.
      " ignore errors
      clear lv_temp.
    endtry.

    " update data
    ls_object = get_object_info( iv_key = iv_key iv_type = iv_type ).
    ls_object-chname = sy-uname.
    ls_object-tdate  = sy-datum.
    ls_object-ttime  = sy-uzeit.

    call function 'WWWDATA_EXPORT'
      exporting
        key               = ls_object
      tables
        mime              = it_data
      exceptions
        wrong_object_type = 1
        export_error      = 2.

    if sy-subrc > 0.
      zcx_w3mime_error=>raise( 'Cannot upload W3xx data' ). "#EC NOTEXT
    endif.

  endmethod.  " update_object.


  method UPDATE_OBJECT_META.

    data: ls_param  type wwwparams,
          ls_object type wwwdatatab.

    ls_param-relid = iv_type.
    ls_param-objid = iv_key.

    if iv_filename is supplied.
      update_object_single_meta(
        iv_type  = iv_type
        iv_key   = iv_key
        iv_param = 'filename'
        iv_value = iv_filename ).
    endif.

    if iv_extension is supplied.
      update_object_single_meta(
        iv_type  = iv_type
        iv_key   = iv_key
        iv_param = 'fileextension'
        iv_value = iv_extension ).
    endif.

    if iv_mime_type is supplied.
      update_object_single_meta(
        iv_type  = iv_type
        iv_key   = iv_key
        iv_param = 'mimetype'
        iv_value = iv_mime_type ).
    endif.

    if iv_version is supplied.
      update_object_single_meta(
        iv_type  = iv_type
        iv_key   = iv_key
        iv_param = 'version'
        iv_value = iv_version ).
    endif.

  endmethod.


  method update_object_single_meta.

    data: ls_param  type wwwparams,
          ls_object type wwwdatatab.

    assert iv_type = 'MI' or iv_type = 'HT'.

    ls_param-relid = iv_type.
    ls_param-objid = iv_key.
    ls_param-name  = iv_param.
    ls_param-value = iv_value.

    call function 'WWWPARAMS_MODIFY_SINGLE'
      exporting
        params = ls_param
      exceptions
        others = 1.

    if sy-subrc > 0.
      zcx_w3mime_error=>raise( |Cannot update W3xx metadata { iv_param }| ). "#EC NOTEXT
    endif.

  endmethod.


  method update_object_x.
    data:
      lt_data type lvc_t_mime,
      lv_size type i.

    call function 'SCMS_XSTRING_TO_BINARY'
      exporting
        buffer        = iv_data
      importing
        output_length = lv_size
      tables
        binary_tab    = lt_data.

    update_object(
        iv_key  = iv_key
        iv_type = iv_type
        iv_size = lv_size
        it_data = lt_data ).

  endmethod.  " update_object_x.
ENDCLASS.

class ZCL_W3MIME_ZIP_WRITER definition
*  public
  final
  create public .

  public section.

    type-pools ABAP .
    methods CONSTRUCTOR
      importing
        !IO_ZIP type ref to CL_ABAP_ZIP optional
        !IV_ENCODING type ABAP_ENCODING optional .
    methods ADD
      importing
        !IV_FILENAME type STRING
        !IV_DATA type STRING .
    methods ADDX
      importing
        !IV_FILENAME type STRING
        !IV_XDATA type XSTRING .
    methods GET_BLOB
      returning
        value(RV_BLOB) type XSTRING .
    methods READ
      importing
        !IV_FILENAME type STRING
      returning
        value(RV_DATA) type STRING
      raising
        ZCX_W3MIME_ERROR .
    methods READX
      importing
        !IV_FILENAME type STRING
      returning
        value(RV_XDATA) type XSTRING
      raising
        ZCX_W3MIME_ERROR .
    methods HAS
      importing
        !IV_FILENAME type STRING
      returning
        value(R_YES) type ABAP_BOOL .
    methods IS_DIRTY
      returning
        value(R_YES) type ABAP_BOOL .
    methods DELETE
      importing
        !IV_FILENAME type STRING
      raising
        ZCX_W3MIME_ERROR .
  protected section.
  private section.

    data MV_IS_DIRTY type ABAP_BOOL .
    data MO_ZIP type ref to CL_ABAP_ZIP .
    data MO_CONV_OUT type ref to CL_ABAP_CONV_OUT_CE .
    data MO_CONV_IN type ref to CL_ABAP_CONV_IN_CE .
    type-pools ABAP .
    data MV_ENCODING type ABAP_ENCODING .
ENDCLASS.



CLASS ZCL_W3MIME_ZIP_WRITER IMPLEMENTATION.


  method add.
    data lv_xdata type xstring.
    mo_conv_out->convert(
      exporting data = iv_data
      importing buffer = lv_xdata ).

    addx(
      iv_filename = iv_filename
      iv_xdata    = lv_xdata ).
  endmethod.  " add.


  method addx.
    mo_zip->delete(
      exporting
        name = iv_filename
      exceptions others = 1 ). " ignore exceptions

    mo_zip->add( name = iv_filename content = iv_xdata ).
    mv_is_dirty = abap_true.
  endmethod.  " addx.


  method constructor.
    if io_zip is bound.
      mo_zip = io_zip.
    else.
      create object mo_zip.
    endif.

    if iv_encoding is not initial.
      mv_encoding = iv_encoding.
    else.
      mv_encoding = '4110'. " UTF8
    endif.

    mo_conv_out = cl_abap_conv_out_ce=>create( encoding = mv_encoding ).
    mo_conv_in  = cl_abap_conv_in_ce=>create( encoding = mv_encoding ).
  endmethod.  " constructor.


  method delete.
    mo_zip->delete( exporting name = iv_filename exceptions others = 4 ).
    if sy-subrc is not initial.
      zcx_w3mime_error=>raise( 'delete failed' ).
    endif.
    mv_is_dirty = abap_true.
  endmethod.


  method get_blob.
    rv_blob = mo_zip->save( ).
    mv_is_dirty = abap_false.
  endmethod.  " get_blob


  method HAS.
    read table mo_zip->files with key name = iv_filename transporting no fields.
    r_yes = boolc( sy-subrc is initial ).
  endmethod.


  method is_dirty.
    r_yes = mv_is_dirty.
  endmethod.


  method READ.
    data:
          lv_xdata type xstring,
          lx       type ref to cx_root.

    lv_xdata = readx( iv_filename ).

    try.
      mo_conv_in->convert( exporting input = lv_xdata importing data = rv_data ).
    catch cx_root into lx.
      zcx_w3mime_error=>raise( msg = 'Codepage conversion error' ). "#EC NOTEXT
    endtry.

  endmethod.


  method READX.

    mo_zip->get(
      exporting
        name    = iv_filename
      importing
        content = rv_xdata
      exceptions zip_index_error = 1 ).

    if sy-subrc is not initial.
      zcx_w3mime_error=>raise( msg = |Cannot read { iv_filename }| ). "#EC NOTEXT
    endif.

    " Remove unicode signatures
    case mv_encoding.
      when '4110'. " UTF-8
        shift rv_xdata left deleting leading  cl_abap_char_utilities=>byte_order_mark_utf8 in byte mode.
      when '4103'. " UTF-16LE
        shift rv_xdata left deleting leading  cl_abap_char_utilities=>byte_order_mark_little in byte mode.
    endcase.

  endmethod.
ENDCLASS.
