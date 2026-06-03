"""
apps/notifications/consumers.py
─────────────────────────────────
WebSocket consumer for real-time push notifications.
Clients connect to: ws://host/ws/notifications/
"""

import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async


class NotificationConsumer(AsyncWebsocketConsumer):
    """Push notifications to connected client via WebSocket."""

    async def connect(self):
        user = self.scope.get('user')
        if not user or not user.is_authenticated:
            await self.close()
            return

        self.user_id    = str(user.id)
        self.group_name = f'notifications_{self.user_id}'

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

        # Send unread count on connect
        unread = await self._get_unread_count(user)
        await self.send(text_data=json.dumps({
            'type': 'connected',
            'unread_count': unread,
        }))

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data):
        """Handle client messages (e.g., mark-read requests)."""
        try:
            data = json.loads(text_data)
            if data.get('action') == 'mark_read':
                await self.channel_layer.group_send(
                    self.group_name,
                    {'type': 'notification_read', 'message': 'ok'}
                )
        except Exception:
            pass

    async def notification_message(self, event):
        """Receive and forward notification from channel layer."""
        await self.send(text_data=json.dumps({
            'type': 'notification',
            'title':   event.get('title'),
            'message': event.get('message'),
            'notif_type': event.get('notif_type'),
            'data':    event.get('data', {}),
        }))

    async def notification_read(self, event):
        await self.send(text_data=json.dumps({'type': 'marked_read'}))

    @database_sync_to_async
    def _get_unread_count(self, user):
        from apps.notifications.models import Notification
        return Notification.objects.filter(user=user, is_read=False).count()
