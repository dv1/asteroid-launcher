#include <QDBusConnection>
#include "externalappmessagesadaptor.h"
#include "externalappmessages.h"

ExternalAppMessages::ExternalAppMessages(QObject *parent, QQmlContext *qmlContext)
	: QObject(parent)
	, m_qmlContext(qmlContext)
{
	new ExternalAppMessagesAdaptor(this);

	QDBusConnection systemBus = QDBusConnection::sessionBus();
	if (!systemBus.registerService("org.asteroidos.ExternalAppMessages")) {
		qWarning("Unable to register D-Bus service org.asteroidos.ExternalAppMessages: %s", systemBus.lastError().message().toUtf8().constData());
	}
	if (!systemBus.registerObject("/org/asteroidos/ExternalAppMessages", this)) {
		qWarning("Unable to register object: %s", systemBus.lastError().message().toUtf8().constData());
	}

	qmlContext->setContextProperty("externalAppMessages", this);
}

void ExternalAppMessages::pushMessage(QString sender, QString ID, QString body)
{
	emit newMessage(sender, ID, body);
}
