import datetime
import decimal

from sqlalchemy import (
    DECIMAL,
    Boolean,
    Date,
    ForeignKeyConstraint,
    Identity,
    Index,
    Integer,
    PrimaryKeyConstraint,
    SmallInteger,
    String,
    Unicode,
    text,
)
from sqlalchemy.dialects.mssql import TINYINT
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class DimDate(Base):
    __tablename__ = 'dim_date'
    __table_args__ = (
        PrimaryKeyConstraint('date_key', name='PK__dim_date__67370B442533A040'),
        Index('UQ__dim_date__A03406DFA63E2A34', 'date_complete', mssql_clustered=False, unique=True)
    )

    date_key: Mapped[int] = mapped_column(Integer, primary_key=True)
    date_complete: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    jour: Mapped[int] = mapped_column(TINYINT, nullable=False)
    mois: Mapped[int] = mapped_column(TINYINT, nullable=False)
    nom_mois: Mapped[str] = mapped_column(Unicode(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    trimestre: Mapped[int] = mapped_column(TINYINT, nullable=False)
    annee: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    semaine_iso: Mapped[int] = mapped_column(TINYINT, nullable=False)
    jour_semaine: Mapped[int] = mapped_column(TINYINT, nullable=False)
    nom_jour: Mapped[str] = mapped_column(Unicode(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    est_weekend: Mapped[bool] = mapped_column(Boolean, nullable=False)
    est_ferie: Mapped[bool] = mapped_column(Boolean, nullable=False)
    saison: Mapped[str] = mapped_column(Unicode(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)

    fait_vente: Mapped[list['FaitVente']] = relationship('FaitVente', back_populates='dim_date')


class DimMagasin(Base):
    __tablename__ = 'dim_magasin'
    __table_args__ = (
        PrimaryKeyConstraint('magasin_key', name='PK__dim_maga__3551AED28AE93C26'),
        Index('UQ__dim_maga__F853647375E7B8BC', 'magasin_id', mssql_clustered=False, unique=True)
    )

    magasin_key: Mapped[int] = mapped_column(Integer, Identity(start=1, increment=1), primary_key=True, autoincrement=True)
    magasin_id: Mapped[int] = mapped_column(Integer, nullable=False)
    nom: Mapped[str] = mapped_column(Unicode(100, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    adresse: Mapped[str] = mapped_column(Unicode(200, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    ville: Mapped[str] = mapped_column(Unicode(100, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    est_cotier: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('((0))'))
    date_ouverture: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    code_postal: Mapped[str | None] = mapped_column(String(10, 'SQL_Latin1_General_CP1_CI_AS'))
    region: Mapped[str | None] = mapped_column(Unicode(100, 'SQL_Latin1_General_CP1_CI_AS'))
    latitude: Mapped[decimal.Decimal | None] = mapped_column(DECIMAL(9, 6))
    longitude: Mapped[decimal.Decimal | None] = mapped_column(DECIMAL(9, 6))

    fait_vente: Mapped[list['FaitVente']] = relationship('FaitVente', back_populates='dim_magasin')


class DimProduit(Base):
    __tablename__ = 'dim_produit'
    __table_args__ = (
        PrimaryKeyConstraint('produit_key', name='PK__dim_prod__2EFD5FF3A57F571E'),
        Index('UQ__dim_prod__59863B4838E412A4', 'produit_id', mssql_clustered=False, unique=True)
    )

    produit_key: Mapped[int] = mapped_column(Integer, Identity(start=1, increment=1), primary_key=True, autoincrement=True)
    produit_id: Mapped[int] = mapped_column(Integer, nullable=False)
    code: Mapped[str] = mapped_column(String(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    nom: Mapped[str] = mapped_column(Unicode(100, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    categorie: Mapped[str] = mapped_column(Unicode(50, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    type_produit: Mapped[str] = mapped_column(Unicode(10, 'SQL_Latin1_General_CP1_CI_AS'), nullable=False)
    prix_catalogue: Mapped[decimal.Decimal] = mapped_column(DECIMAL(6, 2), nullable=False)
    est_actif: Mapped[bool] = mapped_column(Boolean, nullable=False)
    allergenes: Mapped[str | None] = mapped_column(Unicode(200, 'SQL_Latin1_General_CP1_CI_AS'))
    est_vegan: Mapped[bool | None] = mapped_column(Boolean)

    fait_vente: Mapped[list['FaitVente']] = relationship('FaitVente', back_populates='dim_produit')


class FaitVente(Base):
    __tablename__ = 'fait_vente'
    __table_args__ = (
        ForeignKeyConstraint(['date_key'], ['dim_date.date_key'], name='FK__fait_vent__date___412EB0B6'),
        ForeignKeyConstraint(['magasin_key'], ['dim_magasin.magasin_key'], name='FK__fait_vent__magas__4222D4EF'),
        ForeignKeyConstraint(['produit_key'], ['dim_produit.produit_key'], name='FK__fait_vent__produ__4316F928'),
        PrimaryKeyConstraint('date_key', 'magasin_key', 'produit_key', name='PK_fait_vente')
    )

    date_key: Mapped[int] = mapped_column(Integer, primary_key=True)
    magasin_key: Mapped[int] = mapped_column(Integer, primary_key=True)
    produit_key: Mapped[int] = mapped_column(Integer, primary_key=True)
    quantite: Mapped[int] = mapped_column(Integer, nullable=False)
    nb_commandes: Mapped[int] = mapped_column(Integer, nullable=False)
    montant_brut: Mapped[decimal.Decimal] = mapped_column(DECIMAL(12, 2), nullable=False)
    montant_remise: Mapped[decimal.Decimal] = mapped_column(DECIMAL(12, 2), nullable=False)
    montant_net: Mapped[decimal.Decimal] = mapped_column(DECIMAL(12, 2), nullable=False)
    temp_max: Mapped[decimal.Decimal | None] = mapped_column(DECIMAL(4, 1))
    temp_min: Mapped[decimal.Decimal | None] = mapped_column(DECIMAL(4, 1))
    precipitation_mm: Mapped[decimal.Decimal | None] = mapped_column(DECIMAL(5, 1))

    dim_date: Mapped['DimDate'] = relationship('DimDate', back_populates='fait_vente')
    dim_magasin: Mapped['DimMagasin'] = relationship('DimMagasin', back_populates='fait_vente')
    dim_produit: Mapped['DimProduit'] = relationship('DimProduit', back_populates='fait_vente')
