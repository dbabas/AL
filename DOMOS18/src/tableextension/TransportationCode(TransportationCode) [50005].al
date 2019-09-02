tableextension 50005 "Transportation Code" extends "Transportation Code"
{
    fields
    {
        field(50000;Address;text[250])
        {
            CaptionML = ELL='Διεύθυνση',ENU='Address';
            DataClassification = ToBeClassified;
        }
        field(50010;"Reg. No.";text[30])
        {
            CaptionML = ELL='Αρ. Αυτοκιν.',ENU='Reg. No.';
            DataClassification = ToBeClassified;
        }
    }

}