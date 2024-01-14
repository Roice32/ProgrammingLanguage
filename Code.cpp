#include "Code.h"

VarInfo::VarInfo(char type, bool variable = true)
{
    this->type = type;
    this->variable = variable;
}

VarInfo::~VarInfo() {}

void IDList::setValue(const string name, const char* value)
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

void IDList::addVar(const string name, const char type)
{
    VarInfo info(type);
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
        cout << "[Name: " << var.first << ", Type: ";
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
        }
    }
}

IDList::~IDList()
{
    IDs.clear();
}
