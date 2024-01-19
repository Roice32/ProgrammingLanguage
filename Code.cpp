#include <cmath>
#include "Code.h"

extern void yyerror(const char* s);

bool isPlainType(const char *type)
{
    return type[1] == '\0' && (type[0] == 'i' || type[0] == 'f' || type[0] == 'c' || type[0] == 's' || type[0] == 'b');
}

const char* prettyExprType(const char *type)
{
    if (type[1]=='\0')
        switch (type[0])
        {
        case 'i': return "Int"; break;
        case 'f': return "Float"; break;
        case 'c': return "Char"; break;
        case 's': return "String"; break;
        case 'b': return "Bool"; break;
        case 'v': return "Void";
        }
    char temp[64];
    sprintf(temp, "Custom (%s)", type);
    const char* custom = temp;
    return custom;
}

void printToFile(const char* name, const IDList& vars, const FunctionsList& funs)
{
    char base[64], outputFile[128];
    sprintf(base, "%s", name);
    int i = 0;
    while(base[i]!='\0') ++i;
    --i;
    while(base[i]!='.') --i;
    base[i] = '\0';
    snprintf(outputFile, 128, "%s.symbolTable.txt", base);
    remove(outputFile);
    ofstream out(outputFile, ios::app);
    out << "\t\tVariables & Constants:\n";
    vars.printVars(out, false);
    out << "\t\tFunctions:\n";
    funs.printFuns(out);
    out.close();
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
    wasInitialized = false;
    scope = "";
}

VarInfo::VarInfo(const char type, const bool variable, const int size, const string scope)
{
    this->type = type;
    this->customType = "";
    this->isVariable = variable;
    this->wasInitialized = false;
    this->scope = scope;
    this->arrSize = size;
    if (this->arrSize > 0)
    {
        this->array = new VarInfo[arrSize];
        for (int i = 0; i < arrSize; i++)
        {
            this->array[i].type = this->type;
            this->array[i].isVariable = this->isVariable;
            this->array[i].wasInitialized = false;
        }
    }
    else
        this->array = nullptr;
    this->fields = nullptr;
}

VarInfo::VarInfo(const string type, const bool variable, const int size, const string scope, const CustomTypesList *cts)
{
    this->type = 'u';
    this->customType = type;
    this->isVariable = variable;
    this->scope = scope;
    this->arrSize = size;
    if (arrSize > 0)
        array = new VarInfo[arrSize];
    else
        array = nullptr;
    fields = new IDList;
    const IDList *neededFields = cts->CustomTypes.find(type)->second;
    for (const auto &fld : neededFields->IDs)
        fields->addVar(fld.first, variable, fld.second.type, "Member");
}

void VarInfo::printType(ofstream& out) const
{
    switch (this->type)
    {
    case 'i':
        out << "Int";
        break;
    case 'f':
        out << "Float";
        break;
    case 'c':
        out << "Char";
        break;
    case 's':
        out << "String";
        break;
    case 'b':
        out << "Bool";
        break;
    case 'u':
        out << "Custom (" << this->customType << ")";
        break;
    }
}

void VarInfo::printPlainVal(ofstream& out) const
{
    if(!this->wasInitialized)
    {
        out << "(NotInit/NonDeterm)";
        return;
    }
    switch (type)
    {
    case 'i':
        out << this->intVal;
        break;
    case 'f':
        out << this->floatVal;
        break;
    case 'c':
        out << '\'' << this->charVal << '\'';
        break;
    case 's':
        out << '\"' << this->stringVal << '\"';
        break;
    case 'b':
        out << (this->boolVal == true ? "true" : "false");
        break;
    }
}

void VarInfo::printArray(ofstream& out) const
{
    for (int i = 0; i < arrSize; i++)
    {
        array[i].printPlainVal(out);
        if (i < arrSize - 1)
            out << "|";
    }
}

void VarInfo::printCustomVar(ofstream& out) const
{
    for (auto const &fld : fields->IDs)
    {
        out << "[Name: " << fld.first;
        if (fld.second.arrSize > 0)
            out << ", Array size: " << fld.second.arrSize;
        out << ", Type: ";
        switch (fld.second.type)
        {
        case 'i':
            out << "Int, Value: " << fld.second.intVal << "] ";
            break;
        case 'f':
            out << "Float, Value: " << fld.second.floatVal << "] ";
            break;
        case 'c':
            out << "Char, Value: " << fld.second.charVal << "] ";
            break;
        case 's':
            out << "String, Value: \"" << fld.second.stringVal << "\"] ";
            break;
        case 'b':
            out << "Bool, Value: " << (fld.second.boolVal == true ? "true" : "false") << "] ";
            break;
        }
    }
}

VarInfo::~VarInfo() // THROWS SEGMENTATION FAULT
{
    // if(array!=nullptr)
    //     delete[] array;
}

void IDList::setValue(const string name, const char *value) // TO DO: CUSTOM TYPES
{
    VarInfo &ref = this->IDs.at(name);
    switch (ref.type)
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
        ref.boolVal = (value[0] == 't' ? true : false);
        break;
    }
}

bool IDList::isInScope(const string name, const string scope)
{
    if(!this->existsVar(name))
        return false;
    string& ref = this->IDs[name].scope;
    if(ref=="Global Variables")
        return true;
    if(scope.substr(0, ref.length()) == ref)
        return true;
    return false;
}

void IDList::copyValue(const string name, const VarInfo *target)
{
    VarInfo &ref = this->IDs.at(name);
    switch (ref.type)
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
void IDList::addArrayVar(const string name, const bool variable, const string type, const int size, const string scope) // TO DO: CONST/VAR
{
    VarInfo info(type[0], variable, size, scope);
    IDs.insert({name, info});
}

VarInfo *IDList::accessCustomField(const string name, const string field)
{
    return &IDs.find(name)->second.fields->IDs.find(field)->second;
}

// TO DO: ARRAYS
void IDList::addCustomVar(const string name, const bool variable, const string type, const string scope, const CustomTypesList *cts)
{
    VarInfo info(type, variable, 0, scope, cts);
    IDs.insert({name, info});
}

bool IDList::existsVar(const string name) const
{
    return IDs.find(name) != IDs.end();
}

void IDList::printVars(ofstream& out, const bool compact) const
{
    int elemsLeft = this->IDs.size();
    for (const auto &var : IDs)
    {
        --elemsLeft;
        out << "[Name: " << var.first << ", Type: ";
        var.second.printType(out);
        out << ", " << (var.second.isVariable ? "Variable" : "Constant");
        if (var.second.arrSize > 0)
        {
            out << ", Array size: " << var.second.arrSize << ", Values: {";
            var.second.printArray(out);
            out << "}";
        }
        else if (var.second.type == 'u')
        {
            out << ", Fields: { ";
            var.second.printCustomVar(out);
            out << "}";
        }
        else
        {
            out << ", Value: ";
            var.second.printPlainVal(out);
        }
        out << ", Scope: " << var.second.scope << ((compact && elemsLeft==0)?"]":"]\n");
    }
}

IDList& IDList::operator+=(IDList& other)
{
    char errmsg[128];
    for(auto& pair: other.IDs)
        if(this->existsVar(pair.first))
        {
            sprintf(errmsg, "Redeclaration of identifier '%s'.", pair.first.c_str());
            yyerror(errmsg);
        }
        else
            this->IDs.insert({pair.first, other.IDs[pair.first]});
    //delete &other;
    return *this;
}

IDList::~IDList()
{
    IDs.clear();
}

bool CustomTypesList::existsCustom(const string name) const
{
    return CustomTypes.find(name) != CustomTypes.end();
}

void CustomTypesList::addCustom(const string name, IDList *contents)
{
    CustomTypes.insert({name, contents});
}

void CustomTypesList::printCustoms() const
{
    for (const auto &custom : CustomTypes)
    {
        cout << "\t" << custom.first << ":\n";
        for (const auto &content : custom.second->IDs)
        {
            cout << "[Name: " << content.first << ", Type: ";
            switch (content.second.type)
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

FunInfo::FunInfo(const char* returnType, IDList* params, IDList* other)
{
    this->returnType = prettyExprType(returnType);
    this->nParam = 0;
    if(params!=nullptr)
    {
        this->nParam = params->IDs.size();
        this->params = *params;
        //delete params;
    }
    this->hasOther = false;
    if(other!=nullptr)
    {
        this->hasOther = true;
        this->other = *other;
        //delete other;
    }
}

bool FunctionsList::existsFun(const char* name)
{
    return this->Funs.find(name)!=this->Funs.end();
}

void FunctionsList::addFun(const char* name, const char* retType, IDList* params, IDList* other)
{
    FunInfo info(retType, params, other);
    this->Funs.insert({name, info});
}

void FunctionsList::printFuns(ofstream& out) const
{
    for(auto& f: this->Funs)
    {
        out << "\t[Name: " << f.first;
        out << ", Return type: " << f.second.returnType;
        out << ",\nParameters (" << f.second.nParam << "): {";
        f.second.params.printVars(out, true);
        out << " }";
        if(f.second.hasOther)
        {
            out << ",\nOther variables: {";
            f.second.other.printVars(out, true);
            out << "}]\n";
        }
        else
            out << "]\n";
    }
}

ASTNode::ASTNode(const char *type, const char *rawValue)
{
    this->type = type;
    this->typeComputed = false;
    this->rawValue = rawValue;
    this->left = this->right = nullptr;
}

ASTNode::ASTNode(const VarInfo &ref)
{
    this->typeComputed = false;
    if (ref.type == 'u')
    {
        this->type = ref.customType;
        this->rawValue = "!Custom!";
    }
    else
    {
        this->type = ref.type;
        if (ref.type == 's')
            this->rawValue == ref.stringVal;
        else
        {
            char val[64];
            switch (ref.type)
            {
            case 'i':
                sprintf(val, "%d", ref.intVal);
                break;
            case 'f':
                sprintf(val, "%f", ref.floatVal);
                break;
            case 'c':
                sprintf(val, "%c", ref.charVal);
                break;
            case 'b':
                sprintf(val, "%s", ref.boolVal ? "true" : "false");
            }
            this->rawValue = val;
        }
    }
    this->left = this->right = nullptr;
}

const char *ASTNode::computeType(bool &triggerErr)
{
    if (this->typeComputed == true)
        return this->type.c_str();
    this->typeComputed = true;
    if (this->left == nullptr && this->right == nullptr)
        return this->type.c_str();
    string rhs = this->right->computeType(triggerErr);
    if (rhs == "!nE!")
    {
        this->type = "!nE!";
        return this->type.c_str();
    }
    if (this->rawValue == "!")
    {
        if (rhs == "b")
            this->type = "b";
        else
        {
            this->type = "!bMM!";
            triggerErr = true;
        }
        return this->type.c_str();
    }
    string lhs = this->left->computeType(triggerErr);
    if (lhs == "!nE!")
    {
        this->type = "!nE!";
        return this->type.c_str();
    }
    if (lhs != rhs)
    {
        this->type = "!tMM!";
        triggerErr = true;
        return this->type.c_str();
    }
    if (this->type == "!bOp!")
    {
        if (lhs == "b")
            this->type = "b";
        else
        {
            this->type = "!bMM!";
            triggerErr = true;
        }
    }
    if (this->type == "!rOp!")
    {
        if (lhs == "i" || lhs == "f")
            this->type = "b";
        else
        {
            this->type = "!rMM!";
            triggerErr = true;
        }
    }
    if (this->type == "!aOp!")
    {
        if (lhs == "i" || rhs == "f")
            this->type = lhs;
        else
        {
            this->type = "!aMM!";
            triggerErr = true;
        }
    }
    return this->type.c_str();
}

int ASTNode::computeIntVal(bool &triggerErr)
{
    if (this->left == nullptr)
    {
        int result;
        sscanf(this->rawValue.c_str(), "%d", &result);
        return result;
    }
    int lhs = this->left->computeIntVal(triggerErr);
    int rhs = this->right->computeIntVal(triggerErr);
    if (triggerErr)
        return 0;

    if (this->rawValue == "+")
        return lhs + rhs;
    if (this->rawValue == "-")
        return lhs - rhs;
    if (this->rawValue == "*")
        return lhs * rhs;
    if (this->rawValue == "/")
        if (rhs == 0)
        {
            triggerErr = true;
            return 0;
        }
        else
            return lhs / rhs;
    if (this->rawValue == "%")
        if (rhs == 0)
        {
            triggerErr = true;
            return 0;
        }
        else
            return lhs % rhs;
    if (rhs < 0)
    {
        triggerErr = true;
        return 0;
    }
    int result = 1;
    for (int i = 0; i < rhs; i++)
        result *= lhs;
    return result;
}

float ASTNode::computeFloatVal(bool &triggerErr)
{
    if (this->left == nullptr)
    {
        float result;
        sscanf(this->rawValue.c_str(), "%f", &result);
        return result;
    }
    float lhs = this->left->computeFloatVal(triggerErr);
    float rhs = this->right->computeFloatVal(triggerErr);
    if (triggerErr)
        return 0;

    if (this->rawValue == "+")
        return lhs + rhs;
    if (this->rawValue == "-")
        return lhs - rhs;
    if (this->rawValue == "*")
        return lhs * rhs;
    if (this->rawValue == "/")
        if (rhs == 0)
        {
            triggerErr = true;
            return 0;
        }
        else
            return lhs / rhs;
    if (this->rawValue == "%")
    {
        triggerErr = true;
        return 0;
    }
    return pow(lhs, rhs);
}

bool ASTNode::computeBoolVal(bool &triggerErr)
{
    if (this->type == "!bOp!")
        if (this->rawValue[0] == '!')
        {
            bool res = this->right->computeBoolVal(triggerErr);
            if (triggerErr)
                return false;
            return !res;
        }
    if (this->rawValue[0] == '&')
    {
        bool lhs = this->left->computeBoolVal(triggerErr);
        bool rhs = this->right->computeBoolVal(triggerErr);
        if (triggerErr)
            return false;
        return lhs && rhs;
    }
    if (this->rawValue[0] == '|')
    {
        bool lhs = this->left->computeBoolVal(triggerErr);
        bool rhs = this->right->computeBoolVal(triggerErr);
        if (triggerErr)
            return false;
        return lhs || rhs;
    }
    if (this->type == "!rOp!")
        if (this->left->type[0] == 'i')
        {
            int lhs = this->left->computeIntVal(triggerErr);
            int rhs = this->right->computeIntVal(triggerErr);
            if (triggerErr)
                return false;
            if (this->rawValue == "==")
                return lhs == rhs;
            if (this->rawValue == "=/=")
                return lhs != rhs;
            if (this->rawValue == "<=")
                return lhs <= rhs;
            if (this->rawValue == "=>")
                return lhs >= rhs;
            if (this->rawValue == "<")
                return lhs < rhs;
            return lhs > rhs;
        }
        else
        {
            float lhs = this->left->computeFloatVal(triggerErr);
            float rhs = this->right->computeFloatVal(triggerErr);
            if (triggerErr)
                return false;
            if (this->rawValue == "==")
                return lhs == rhs;
            if (this->rawValue == "=/=")
                return lhs != rhs;
            if (this->rawValue == "<=")
                return lhs <= rhs;
            if (this->rawValue == "=>")
                return lhs >= rhs;
            if (this->rawValue == "<")
                return lhs < rhs;
            return lhs > rhs;
        }
    return false; // Here only to (safely) supress a warning.
}

void ASTNode::destroyTree()
{
    if (this->left != nullptr)
        this->left->destroyTree();
    if (this->right != nullptr)
        this->right->destroyTree();
    delete this;
}
