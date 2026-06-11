"""Add status column to meals

Revision ID: 003
down_revision = '002'
branch_labels = None
depends_on = None
"""

from alembic import op
import sqlalchemy as sa


def upgrade() -> None:
    op.add_column(
        "meals",
        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default="pending",
        ),
    )
    op.execute("UPDATE meals SET status = 'completed' WHERE health_score IS NOT NULL")


def downgrade() -> None:
    op.drop_column("meals", "status")