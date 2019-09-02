tableextension 50003 "Document Header" extends "Document Header"
{
    fields
    {
        field(50000;"Net Weight";Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(50010;"Shipping Agent";text[250])
        {
            DataClassification = ToBeClassified;
        }
    }
}