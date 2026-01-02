@EndUserText.label: 'Abstract Entity for Attachment Popup'
define root abstract entity ZA_MSATTACH
{
  // Dummy is a dummy field
  @UI.hidden: true
  dummy : sysuuid_x16;

  _StreamProperties : association [1] to ZA_MSFILESTREAM on 1 = 1;
}
