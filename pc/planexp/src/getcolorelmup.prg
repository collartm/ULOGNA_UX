/* $Id$
****************************************************************************
* pc_bas_get_color_elm_up - rch color elm up
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de retourner une couleur pour un  �l�ment UP
--
-- ATTENTION ! peut �tre appel�e dans un select
--
-- PARAMETRES :
-- ------------
--  - commande
--  - lig com
--  - produit
--  - couleur par d�faut
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01a,24.09.13,tcho    cr�ation
-- 00a,08.09.06,GENMPD  version 2.7
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  code couleur
--
-- COMMIT :
-- --------
--   NON

CREATE OR REPLACE FUNCTION pc_bas_get_color_elm_up (p_no_com varchar2 DEFAULT NULL,
                                  p_no_lig number default null,
                                  p_cod_pro varchar2 default null,
                                  p_col_def varchar2 default null,
                                  p_typ_up varchar2 default null,
                                  p_cod_up  varchar2 default null  )
RETURN VARCHAR2 deterministic
IS
--    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01a $Revision$';
--    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_get_color_elm_up';
--    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
--    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
--    err_except          EXCEPTION;

    v_ret varchar2(100);

    v_tmp number;

    /* SYSTEM U : connaitre le nombre de "couches" */
    cursor c_stack is
        select count(distinct nvl(cle_rgp_pal_pref_A_1,'#')) nb,
               min(cle_rgp_pal_pref_A_1) cod_stack_min,
               max(cle_rgp_pal_pref_A_1) cod_stack_max,
               min(decode(l.cod_pro,p_cod_pro,cle_rgp_pal_pref_A_1,null)) cod_stack_pro
        from pc_lig_com l,pc_uee_det d,pc_uee e
        where l.no_com=d.no_com
           and l.no_lig_com=d.no_lig_com
           and d.no_uee=e.no_uee
          and e.typ_up=p_typ_up
          and e.cod_up=p_cod_up;

   r_stack c_stack%ROWTYPE;

BEGIN

    /* standard */
    v_ret := p_col_def;

    /* SPECIF SYSTEM U  */

    open c_stack;
    fetch c_stack into r_stack;
    close c_stack;

    if r_stack.nb >1 then -- uniquement si plusieurs couches
        -- recup des 3 derniers chiffres pour faire une couleur
        if substr(p_cod_pro,-2,1)='-' then
            --v_tmp :=ceil(0+nvl(sqrt(su_bas_to_number(substr(p_cod_pro,-5,3)))/32,1)*192);
            v_tmp :=ceil(0+nvl((su_bas_to_number(substr(p_cod_pro,-5,3)))/1000,1)*192);
        else
            v_tmp :=ceil(0+nvl(su_bas_to_number(substr(p_cod_pro,-3))/1000,1)*192);
        end if;

        -- rgb / couche
        if nvl(r_stack.cod_stack_min,'#')=nvl(r_stack.cod_stack_pro,'#') then
            v_ret := 'r255g'||v_tmp||'b'||v_tmp;
        elsif nvl(r_stack.cod_stack_max,'#')=nvl(r_stack.cod_stack_pro,'#') then
            v_ret := 'r'||v_tmp||'g'||v_tmp||'b255';
        elsif r_stack.nb=3 then
            v_ret := 'r'||v_tmp||'g255b'||v_tmp;
        elsif r_stack.nb=4 then -- gris pour stacks milieu
            v_ret := 'r'||v_tmp||'g'||v_tmp||'b'||v_tmp;
        end if;


    end if;
    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        RETURN null;
END;
/
show errors;

