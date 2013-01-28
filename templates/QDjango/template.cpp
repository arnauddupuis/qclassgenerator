#include "/*__CLASS_FILE__*/.h"

/*__CLASS_NAME__*/::/*__CLASS_NAME__*/(QObject *parent) :
    QDjangoModel(parent)/*__INLINE_INIT__*/
{
/*__BODY_INIT__*/
}

/*__CLASS_NAME__*/::/*__CLASS_NAME__*/(const /*__CLASS_NAME__*/ &p_obj):QDjangoModel(p_obj.parent()){
/*__COPY_OPERATOR_CODE__*/
}

/*__CLASS_NAME__*/& /*__CLASS_NAME__*/::operator=(const /*__CLASS_NAME__*/& p_obj){
	if( this == &p_obj )
		return *this;
/*__COPY_OPERATOR_CODE__*/
	return *this;
}

// Setters (slots)
/*__SETTERS__*/

// Getters
/*__GETTERS__*/

