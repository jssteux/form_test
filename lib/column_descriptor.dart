
class ColumnDescriptor  {
  final String name;
  final String type;
  final String label;
  final String reference;
  final bool mandatory;
  final String defaultValue;
  final bool cascadeDelete;
  ColumnDescriptor(this.name,this.type,this.label, this.reference, this.cascadeDelete, this.mandatory, this.defaultValue);
}