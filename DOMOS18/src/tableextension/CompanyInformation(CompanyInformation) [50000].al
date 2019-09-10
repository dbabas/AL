tableextension 50000 "Company Information" extends "Company Information"
{
    fields
    {
        field(50000; "ISO Logo"; blob)
        {
            Subtype = Bitmap;
            DataClassification = ToBeClassified;
        }
        field(50010; "Bank Name 4"; Text[50])
        {
            CaptionML = ELL='Ονομασία Τράπεζας 4',ENU='Bank Name 4';
            DataClassification = ToBeClassified;
        }
        field(50020;"Bank Account No. 4"; Text[30])
        {
            CaptionML = ELL='Αρ. Τραπεζικού Λογαριασμού 4',ENU='Bank Account No. 4';
            DataClassification = ToBeClassified;
        }
    }
    
}