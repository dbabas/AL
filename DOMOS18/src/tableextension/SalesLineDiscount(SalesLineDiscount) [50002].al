tableextension 50002 "Sales Line Discount" extends "Sales Line Discount"
{
    fields
    {
        field(50000; "Item Disc. Group Description"; Text[50])
        {
            CaptionML = ELL = 'Περιγραφή Ομ. Έκπτ. Είδους', ENU = 'Item Disc. Group Description';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Lookup ("Item Discount Group".Description WHERE ("Code" = FIELD ("Code")));
        }
        

    }

}