"""
apps/notifications/tasks.py
────────────────────────────
Celery tasks for:
  - Sending email notifications
  - Creating in-app notification records
  - Notifying doctors of new cases
  - Notifying patients of approval/rejection
"""

from celery import shared_task
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

User = get_user_model()


def _create_notification(user_id, type_, title, message, data=None):
    """Helper to create a Notification record."""
    try:
        from apps.notifications.models import Notification
        user = User.objects.get(id=user_id)
        Notification.objects.create(
            user=user,
            type=type_,
            title=title,
            message=message,
            data=data or {},
        )
    except Exception as e:
        logger.error('Failed to create notification: %s', str(e))


# ── Doctor notifications ──────────────────────────────────────────────────────

@shared_task(bind=True, max_retries=3)
def notify_doctors_new_case(self, case_id: str):
    """Notify all approved doctors that a new case needs review."""
    try:
        from apps.cases.models import Case
        from apps.accounts.models import DoctorProfile
        from apps.notifications.models import Notification

        case = Case.objects.select_related('patient').get(id=case_id)
        approved_doctors = DoctorProfile.objects.filter(
            status=DoctorProfile.Status.APPROVED
        ).select_related('user')

        for profile in approved_doctors:
            doctor = profile.user
            _create_notification(
                user_id=str(doctor.id),
                type_=Notification.Type.CASE_SUBMITTED,
                title='New Case Awaiting Review',
                message=f'Patient {case.patient.name} submitted a new case. Predicted: {case.predicted_disease or "Pending"}.',
                data={'case_id': case_id, 'case_number': case.case_number},
            )

            # Email notification
            if doctor.email:
                try:
                    send_mail(
                        subject='[MedAI] New Patient Case Awaiting Your Review',
                        message=(
                            f'Dear Dr. {doctor.name},\n\n'
                            f'A new patient case ({case.case_number}) is awaiting your review.\n'
                            f'Patient: {case.patient.name}\n'
                            f'Predicted disease: {case.predicted_disease or "Pending"}\n\n'
                            f'Please log in to MedAI to review this case.\n\n'
                            f'MedAI Team'
                        ),
                        from_email=settings.DEFAULT_FROM_EMAIL,
                        recipient_list=[doctor.email],
                        fail_silently=True,
                    )
                except Exception as e:
                    logger.warning('Failed to send email to %s: %s', doctor.email, str(e))

    except Exception as exc:
        logger.exception('notify_doctors_new_case failed for case %s', case_id)
        raise self.retry(exc=exc, countdown=60)


@shared_task(bind=True, max_retries=3)
def notify_patient_case_approved(self, case_id: str):
    """Notify patient that their case has been approved."""
    try:
        from apps.cases.models import Case
        from apps.notifications.models import Notification

        case = Case.objects.select_related('patient').get(id=case_id)
        patient = case.patient

        _create_notification(
            user_id=str(patient.id),
            type_=Notification.Type.CASE_APPROVED,
            title='Your Prescription is Ready!',
            message='Your doctor has reviewed your case and approved your prescription. You can now view your medications.',
            data={'case_id': case_id, 'case_number': case.case_number},
        )

        send_mail(
            subject='[MedAI] Your Prescription Has Been Approved',
            message=(
                f'Dear {patient.name},\n\n'
                f'Your doctor has reviewed your case ({case.case_number}) and your prescription is now ready.\n\n'
                f'Please log in to MedAI to view your approved medications and dosage instructions.\n\n'
                f'⚠️ Always follow your doctor\'s instructions carefully.\n\n'
                f'MedAI Team'
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[patient.email],
            fail_silently=True,
        )

    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


@shared_task(bind=True, max_retries=3)
def notify_patient_case_rejected(self, case_id: str):
    """Notify patient that their case was rejected."""
    try:
        from apps.cases.models import Case
        from apps.notifications.models import Notification

        case = Case.objects.select_related('patient').get(id=case_id)
        patient = case.patient

        _create_notification(
            user_id=str(patient.id),
            type_=Notification.Type.CASE_REJECTED,
            title='Case Update',
            message=f'Your doctor has reviewed your case. Reason: {case.rejection_reason or "Please resubmit with more information."}',
            data={'case_id': case_id, 'case_number': case.case_number},
        )

        send_mail(
            subject='[MedAI] Case Update',
            message=(
                f'Dear {patient.name},\n\n'
                f'Your doctor reviewed case {case.case_number}.\n'
                f'Reason: {case.rejection_reason or "Please resubmit with updated information."}\n\n'
                f'You can submit a new case from the app.\n\n'
                f'MedAI Team'
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[patient.email],
            fail_silently=True,
        )

    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


# ── Admin notifications ───────────────────────────────────────────────────────

@shared_task(bind=True, max_retries=3)
def send_admin_new_doctor_notification(self, doctor_user_id: str):
    """Notify all admin users that a new doctor registration is pending."""
    try:
        from apps.notifications.models import Notification

        doctor = User.objects.get(id=doctor_user_id)
        admins = User.objects.filter(role='admin', is_active=True)

        for admin in admins:
            _create_notification(
                user_id=str(admin.id),
                type_=Notification.Type.NEW_DOCTOR,
                title='New Doctor Registration Pending',
                message=f'Dr. {doctor.name} ({doctor.email}) has registered and is awaiting account approval.',
                data={'doctor_id': doctor_user_id},
            )

    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


@shared_task(bind=True, max_retries=3)
def send_doctor_approval_email(self, doctor_user_id: str):
    """Send approval confirmation email to a doctor."""
    try:
        doctor = User.objects.get(id=doctor_user_id)
        _create_notification(
            user_id=str(doctor.id),
            type_='doctor_approved',
            title='Account Approved!',
            message='Your doctor account has been approved. You can now log in and start reviewing patient cases.',
            data={},
        )
        send_mail(
            subject='[MedAI] Your Doctor Account Has Been Approved',
            message=(
                f'Dear Dr. {doctor.name},\n\n'
                f'Your MedAI doctor account has been reviewed and approved!\n\n'
                f'You can now log in to start reviewing patient cases and issuing prescriptions.\n\n'
                f'MedAI Team'
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[doctor.email],
            fail_silently=True,
        )
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)


@shared_task(bind=True, max_retries=3)
def send_doctor_rejection_email(self, doctor_user_id: str, reason: str):
    """Send rejection email to a doctor."""
    try:
        doctor = User.objects.get(id=doctor_user_id)
        send_mail(
            subject='[MedAI] Doctor Account Registration Update',
            message=(
                f'Dear Dr. {doctor.name},\n\n'
                f'Unfortunately, your MedAI doctor account registration was not approved at this time.\n\n'
                f'Reason: {reason}\n\n'
                f'If you believe this is an error, please contact our support team.\n\n'
                f'MedAI Team'
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[doctor.email],
            fail_silently=True,
        )
    except Exception as exc:
        raise self.retry(exc=exc, countdown=60)
