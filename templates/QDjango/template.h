#ifndef /*__MIPT__*/
#define /*__MIPT__*/

#include <QObject>
#include "QDjangoModel.h"
/*__INCLUDES__*/
/*__EXTRA_INCLUDES__*/

class /*__CLASS_NAME__*/ : public QDjangoModel
{
	Q_OBJECT
/*__PROPERTIES__*/

public:
	/*!
	Constructs a new /*__CLASS_NAME__*/ object.
	*/
	explicit /*__CLASS_NAME__*/(QObject *parent = 0);
	explicit /*__CLASS_NAME__*/(const /*__CLASS_NAME__*/ &p_obj);
	/*__CLASS_NAME__*/& operator=(/*__CLASS_NAME__*/& p_obj);
    
	// Getters
	/*__GETTERS_H__*/

private:
	// Member variables
	/*__MEMBER_VARIABLES__*/

signals:
	/*__SIGNALS__*/
    
public slots:
	/*__SETTERS_H__*/

};

#endif // /*__MIPT__*/
