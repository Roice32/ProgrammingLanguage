#include "Code.h"

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
}

VarInfo::VarInfo(const char type, const bool variable, const int size = 0)
{
    this->type = type;
    this->isVariable = variable;
    this->arrSize = size;
    if(arrSize>0)
        array = new VarInfo[arrSize];
    else
        array = nullptr;
}

VarInfo::VarInfo(const string type, const bool variable, const int size = 0)
{
    this->type = 'u';
    this->customType = type;
    this->isVariable = variable;
    this->arrSize = size;
    if(arrSize>0)
        array = new VarInfo[arrSize];
    else
        array = nullptr;
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

void IDList::addVar(const string name, const char type)  // TO DO: CONST/VAR
{
    VarInfo info(type, true);
    IDs.insert({name, info});
}

void IDList::addArrayVar(const string name, const char type, const int size)  // TO DO: CONST/VAR
{
    VarInfo info(type, true, size);
    IDs.insert({name, info});
}

void IDList::addCustomVar(const string name, const string type)
{
    VarInfo info(type, true);
    IDs.insert({name, info});
}

bool IDList::existsVar(const string name) const
{
    return IDs.find(name) != IDs.end();
}

void IDList::printVars() const
{
    for (const auto &var : IDs)
    {
        cout << "[Name: " << var.first;
        if(var.second.arrSize>0)
            cout << ", Array size: " << var.second.arrSize; // TO DO: ALSO PRINT VALUES
        cout << ", Type: ";
        switch(var.second.type)
        {
        case 'i':
            cout << "Int, Value: " << var.second.intVal << "]\n";
        break;
        case 'f':
            cout << "Float, Value: " << var.second.floatVal << "]\n";
        break;
        case 'c':
            cout << "Char, Value: " << var.second.charVal << "]\n";
        break;
        case 's':
                cout << "String, Value: \"" << var.second.stringVal << "\"]\n";
        break;
        case 'b':
            cout << "Bool, Value: " << (var.second.boolVal==true?"true":"false") << "]\n";
        break;
        case 'u':
            cout << "Custom (" << var.second.customType << ")]\n";
        break;
        }
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

void CustomTypesList::addCustom(const string name, const IDList contents)
{
    CustomTypes.insert({name, contents});
}

void CustomTypesList::printCustoms() const
{
    cout << "Custom Types:\n";
    for(const auto &custom : CustomTypes)
    {
        cout << "\t" << custom.first << ":\n";
        for(const auto &content : custom.second.IDs)
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