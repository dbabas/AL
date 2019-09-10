tableextension 50007 "CPN Posting Group" extends "CPN Posting Group"
{
    fields
    {
        field(50000;"Delivery/Receipt";Option)
        {
            OptionMembers = " ","Delivery","Receipt";
            OptionCaptionML = ELL='" ","Παράδοση","Παραλαβή"',ENU='" ","Delivery","Receipt"';
            DataClassification = ToBeClassified;
        }
    }
    

}