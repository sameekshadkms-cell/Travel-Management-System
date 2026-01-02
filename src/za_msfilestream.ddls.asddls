@EndUserText.label: 'Abstract Entity for File Stream'
define  root abstract entity ZA_MSFILESTREAM
{
  @EndUserText.label: 'Select Excel file'
  @Semantics.largeObject: { mimeType: 'mimeType',
                            fileName: 'fileName',
                            acceptableMimeTypes: [ 'application/vnd.openxmlformats-officedocument.spreadsheetml.*',
                                                   'application/vnd.ms-excel' ],
                            contentDispositionPreference: #INLINE }
  attachment            : /dmo/attachment;

  @UI.hidden: true
  mimeType             : /dmo/mime_type;

  @UI.hidden: true
  fileName             : /dmo/filename;
}
