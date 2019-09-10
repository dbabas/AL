tableextension 50008 "Item" extends Item
{
    fields
    {
        field(50000;"Foreign Description";Text[250])
        {
            CaptionML = ELL='Ξενόγλωσση Περιγραφή',ENU='Foreign Description';
            DataClassification = ToBeClassified;
        }
        field(50010;"Price List No.";Code[10])
        {
            CaptionML = ELL='Κωδ.Τιμοκαταλόγου',ENU='Price List No.';
            DataClassification = ToBeClassified;
        }
    }
}