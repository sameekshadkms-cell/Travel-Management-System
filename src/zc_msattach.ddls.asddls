@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '###GENERATED Core Data Service Entity'
@Metadata.allowExtensions: true
define view entity ZC_MSATTACH as projection on ZR_MSATTACH
{
  key AttachUuid,

      TravelUuid,
      Attachment,
      MimeType,
      FileName,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      /* Associations */
      _Travel : redirected to parent ZC_MSTRAVEL
}
