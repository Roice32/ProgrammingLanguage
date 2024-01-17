#include "Code.h"

bool isPlainType(const char* type)
{
    return type[1]=='\0' && (type[0]=='i' || type[0]=='f' || type[0]=='c' || type[0]=='s' || type[0]=='b');
}

VarInfo::VarInfo()
{
    type = 0;
    customType = "";
    intVal = 0;
    floatVal = 0;
    charVal = 0;
    stringVal = "";
    boolVal = false;
    arrSize = 0;
    array = nullptr;
    isVariable = false;
    scope = "";
}

VarInfo::VarInfo(const char type, const bool variable, const int size, const string scope)
{
    this->type = type;
    this->customType = "";
    this->isVariable = variable;
    this->scope = scope;
    this->arrSize = size;
    if(this->arrSize>0)
    {
        this->array = new VarInfo[arrSize];
        for(int i=0; i < arrSize; i++)
            this->array[i].type = this->type;
    }
    else
        this->array = nullptr;
    this->fields = nullptr;
}

// LORD KNOWS HOW TO MODIFY THIS LATER
VarInfo::VarInfo(const string type, const bool variable, const int size, const string scope, const CustomTypesList* cts)
{
    this->type = 'u';
    this->customType = type;
    this->isVariable = variable;
    this->scope = scope;
    this->arrSize = size;
    if(arrSize>0)
        array = new VarInfo[arrSize];
    else
        array = nullptr;
    fields = new IDList;
    const IDList* neededFields = cts->CustomTypes.find(type)->second;
    for(const auto& fld : neededFields->IDs)
        fields->addVar(fld.first, variable, fld.second.type, "Inherited (Member)");
}

void VarInfo::printType() const
{
    switch(this->type)
    {
    case 'i':
        cout << "Int";
    break;
    case 'f':
        cout << "Float";
    break;
    case 'c':
        cout << "Char";
    break;
    case 's':
        cout << "String";
    break;
    case 'b':
        cout << "Bool";
    break;
    case 'u':
        cout << "Custom (" << this->customType << ")";
    break;
    }
}

void VarInfo::printPlainVal() const
{
    switch(type)
    {
    case 'i':
        cout << this->intVal;
    break;
    case 'f':
        cout << this->floatVal;
    break;
    case 'c':
        cout << '\'' << this->charVal << '\'';
    break;
    case 's':
        cout << '\"' << this->stringVal << '\"';
    break;
    case 'b':
        cout << (this->boolVal==true?"true":"false");
    break;
    }
}

void VarInfo::printArray() const
{
    for(int i=0; i<arrSize; i++)
    {
        array[i].printPlainVal();
        if(i<arrSize-1)
            cout << "|";
    }
}

void VarInfo::printCustomVar() const
{
    for(auto const &fld: fields->IDs)
    {
        cout << "[Name: " << fld.first;
        if(fld.second.arrSize>0)
            cout << ", Array size: " << fld.second.arrSize;
        cout << ", Type: ";
        switch(fld.second.type)
        {
        case 'i':
            cout << "Int, Value: " << fld.second.intVal << "] ";
        break;
        case 'f':
            cout << "Float, Value: " << fld.second.floatVal << "] ";
        break;
        case 'c':
            cout << "Char, Value: " << fld.second.charVal << "] ";
        break;
        case 's':
                cout << "String, Value: \"" << fld.second.stringVal << "\"] ";
        break;
        case 'b':
            cout << "Bool, Value: " << (fld.second.boolVal==true?"true":"false") << "] ";
        break;
        }
    }
}

VarInfo::~VarInfo() // F-ER THROWS SEGMENTATION FAULT
{
    //if(array!=nullptr)
    //    delete[] array;
}

void IDList::setValue(const string name, const char* value) // TO DO: CUSTOM TYPES
{
    VarInfo &ref = this->IDs.at(name);
    switch(ref.type)
    {
    case 'i':
        sscanf(value, "%d", &ref.intVal);
    break;
    case 'f':
        sscanf(value, "%f", &ref.floatVal);
    break;
    case 'c':
        ref.charVal = value[0];
    break;
    case 's':
        ref.stringVal = value;
    break;
    case 'b':
        ref.boolVal = (value[0]=='t'?true:false);
    break;
    }
}

// TO DO: MODIFY THIS TO WORK FOR ARRAYS
void IDList::copyValue(const string name, const VarInfo *target)
{
    VarInfo &ref = this->IDs.at(name);
    switch(ref.type)
    {
    case 'i':
        ref.intVal = target->intVal;
    break;
    case 'f':
        ref.floatVal = target->floatVal;
    break;
    case 'c':
        ref.charVal = target->charVal;
    break;
    case 's':
        ref.stringVal = target->stringVal;
    break;
    case 'b':
        ref.boolVal = target->boolVal;
    break;
    }
}

void IDList::addVar(const string name, const bool variable, const char type, const string scope)
{
    VarInfo info(type, variable, 0, scope);
    IDs.insert({name, info});
}

// MAKE THIS WORK FOR CUSTOMS
void IDList::addArrayVar(const string name, const bool variable, const string type, const int size, const string scope)  // TO DO: CONST/VAR
{
    VarInfo info(type[0], variable, size, scope);
    IDs.insert({name, info});
}

VarInfo* IDList::accessCustomField(const string name, const string field)
{
    return &IDs.find(name)->second.fields->IDs.find(field)->second;
}

// TO DO: ARRAYS
void IDList::addCustomVar(const string name, const bool variable, const string type, const string scope, const CustomTypesList* cts)
{
    VarInfo info(type, variable, 0, scope, cts);
    IDs.insert({name, info});
}

bool IDList::existsVar(const string name) const
{
    return IDs.find(name) != IDs.end();
}

void IDList::printVars() const // TO DO: ALSO PRINT VALUES FOR ARRAYS & CUSTOMS
{
    for (const auto &var : IDs)
    {
        cout << "[Name: " << var.first << ", Type: ";
        var.second.printType();
        cout << ", " << (var.second.isVariable?"Variable":"Constant");
        if(var.second.arrSize>0)
        {
            cout << ", Array size: " << var.second.arrSize << ", Values: {";
            var.second.printArray();
            cout << "}";
        }
        else if(var.second.type=='u')
        {
            cout << ", Fields: { ";
            var.second.printCustomVar();
            cout << "}";
        }
        else
        {
            cout << ", Value: ";
            var.second.printPlainVal();
        }
        cout << ", Scope: " << var.second.scope << "]\n";
    }
}

IDList::~IDList()
{
    IDs.clear();
}

bool CustomTypesList::existsCustom(const string name) const
{
    return CustomTypes.find(name) != CustomTypes.end();
}

void CustomTypesList::addCustom(const string name, IDList* contents)
{
    CustomTypes.insert({name, contents});
}

void CustomTypesList::printCustoms() const
{
    for(const auto &custom : CustomTypes)
    {
        cout << "\t" << custom.first << ":\n";
        for(const auto &content : custom.second->IDs)
        {
            cout << "[Name: " << content.first << ", Type: ";
            switch(content.second.type)
            {
            case 'i':
                cout << "Int]\n";
            break;
            case 'f':
                cout << "Float]\n";
            break;
            case 'c':
                cout << "Char]\n";
            break;
            case 's':
                cout << "String]\n";
            break;
            case 'b':
                cout << "Bool]\n";
            break;
            }
        }
    }
}

CustomTypesList::~CustomTypesList()
{
    CustomTypes.clear();
}