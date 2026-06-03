"""
apps/accounts/management/commands/create_admin.py
───────────────────────────────────────────────────
Usage:
  python manage.py create_admin --email admin@medai.app --password securepass123

Creates an admin-role superuser that can access /admin/ and all admin APIs.
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Create a MedAI admin superuser'

    def add_arguments(self, parser):
        parser.add_argument('--email',    type=str, required=True,  help='Admin email')
        parser.add_argument('--password', type=str, required=True,  help='Admin password')
        parser.add_argument('--name',     type=str, default='Admin', help='Admin display name')

    def handle(self, *args, **options):
        email    = options['email']
        password = options['password']
        name     = options['name']

        if User.objects.filter(email=email).exists():
            self.stdout.write(self.style.WARNING(f'User with email {email} already exists.'))
            return

        user = User.objects.create_superuser(
            email=email,
            password=password,
            name=name,
        )

        self.stdout.write(self.style.SUCCESS(
            f'\n✅ Admin user created successfully!\n'
            f'   Email:    {user.email}\n'
            f'   Name:     {user.name}\n'
            f'   Role:     {user.role}\n'
            f'\n   Login at: http://localhost:8000/admin/\n'
        ))
