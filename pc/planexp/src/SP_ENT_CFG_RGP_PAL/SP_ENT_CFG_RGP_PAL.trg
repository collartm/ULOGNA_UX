-- $Id$
-- DESCRIPTION :
-- -------------
-- Triggers sur SP_ENT_CFG_RGP_PAL
CREATE OR REPLACE TRIGGER TUB_SP_ENT_CFG_RGP_PAL BEFORE UPDATE
ON SP_ENT_CFG_RGP_PAL FOR EACH ROW
BEGIN
    :new.dat_maj := SYSDATE;
    :new.usr_maj := su_global_pkv.v_user;
    :new.ope_maj:=nvl(su_global_pkv.v_cod_ope,:new.usr_maj);
    :new.info_pos_maj:=nvl(su_global_pkv.v_info_pos,su_global_pkv.v_no_pos);
END;
/

CREATE OR REPLACE TRIGGER TIB_SP_ENT_CFG_RGP_PAL BEFORE INSERT
ON SP_ENT_CFG_RGP_PAL FOR EACH ROW
BEGIN
    IF :new.etat_phenyx=0 or :new.etat_phenyx IS NULL OR su_global_pkv.r_su_ope.typ_ope!='DEV' THEN
        :new.etat_phenyx:=su_global_pkv.v_mode_phenyx;
    END IF;
    IF su_global_pkv.v_user IS NULL OR su_global_pkv.v_cod_ope IS NULL THEN -- init ope
        su_global_pkv.v_user:=USER;
        su_global_pkv.v_cod_ope:=USER;
    END IF;
    IF su_global_pkv.v_info_pos IS NULL and su_global_pkv.v_no_pos is not null THEN -- init pos
        su_global_pkv.v_info_pos:=su_global_pkv.v_no_pos;
    END IF;
    :new.dat_crea:=SYSDATE;
    :new.usr_crea:=su_global_pkv.v_user;
    :new.ope_crea:=su_global_pkv.v_cod_ope;
    :new.info_pos_crea:=su_global_pkv.v_info_pos;
    :new.dat_maj:=:new.dat_crea;
    :new.usr_maj:=:new.usr_crea;
    :new.ope_maj:=:new.ope_crea;
    :new.info_pos_maj:=:new.info_pos_crea;
END;
/

