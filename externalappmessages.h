#ifndef EXTERNALAPPMESSAGES_H
#define EXTERNALAPPMESSAGES_H

#include <QObject>
#include <QString>
#include <QQmlContext>

class ExternalAppMessages : public QObject
{
	Q_OBJECT

public:
	explicit ExternalAppMessages(QObject *parent, QQmlContext *qmlContext);

signals:
	void newMessage(QString const &sender, QString const &ID, QString const &body);

public slots:
	void pushMessage(QString sender, QString ID, QString body);

private:
	QQmlContext *m_qmlContext;
};

#endif // EXTERNALAPPMESSAGES_H
