class ItemToRemove  {
  final String sheetName;
  final String id;
  final int startIndex;
  final int endIndex;

  ItemToRemove(this.sheetName, this.id, this.startIndex, this.endIndex);
}



class FileSyncInfos  {
  final DateTime? lastModifiedDate;
  List<String> modifiedUrls;

  FileSyncInfos( this.lastModifiedDate, this.modifiedUrls );
}