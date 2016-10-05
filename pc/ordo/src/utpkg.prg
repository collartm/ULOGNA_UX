/* $Id$ */
CREATE OR REPLACE
PACKAGE BODY pc_ut_pkg AS

/*
****************************************************************************
* pc_bas_ut_existe_et_ouverte - Regarde à partir du cod_up / typ_up si une UT
*							    exite et est ouverte
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de regarder à partir du cod_up / typ_up si une UT
-- exite déjà et si elle est ouverte.
-- Si elle a déjà été créée et est ouverte, alors on rend OUI,
-- sinon on rend NON.
--
-- PARAMETRES :
-- ------------
--  p_cod_up : le code up
--	p_typ_up : le type up
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- --------------------------------------------------------------------------
-- 03a,01.04.15,pluc    Spec. SUO : forcer 1 UP = 1 UT en ne testant pas le no_dpt
-- 02a,08.12.09,mnev    Ajoute no_dpt en paramètre pour assurer la selection
--                      d'une UT du bon départ.
-- 01c,30.07.09,mnev    Corrige test sur rch_ut
-- 01b,21.05.08,mnev    Ajout test cod_grp_pss IS NULL
-- 01a,25.04.07,xxxx    ...
-- 00a,25.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_ut_existe_et_ouverte (p_cod_up         PC_UP.cod_up%TYPE,
							          p_typ_up         PC_UP.typ_up%TYPE,
                                      p_grp_pss        PC_UT.cod_grp_pss%TYPE,
                                      p_no_dpt         PC_UT.no_dpt%TYPE,
                                      p_cod_ut_sup OUT PC_UT.cod_ut_sup%TYPE,
                                      p_typ_ut_sup OUT PC_UT.typ_ut_sup%TYPE)
RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 02a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_ut_existe_et_ouverte';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    CURSOR c_rch_ut(x_cod_up PC_UT.cod_up%TYPE,
			        x_typ_up PC_UP.typ_up%TYPE) IS
        SELECT cod_ut, typ_ut
        FROM pc_ut
        WHERE cod_up = x_cod_up AND typ_up = x_typ_up AND
              (NVL(cod_grp_pss,'#NULL#') = NVL(p_grp_pss,'#NULL#') OR cod_grp_pss IS NULL) AND
              etat_pal_ut = '1' --AND -- palettisation toujours autorisée ...
              --no_dpt = p_no_dpt   -- Spec SUO : forcer 1 UP = 1UT
        ORDER BY cod_ut DESC;

    r_rch_ut        c_rch_ut%ROWTYPE;

BEGIN

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : p_cod_up=' || p_cod_up);
		su_bas_put_debug(v_nom_obj||' : p_typ_up=' || p_typ_up);
		su_bas_put_debug(v_nom_obj||' : p_grp_pss=' || p_grp_pss);
    END IF;

    /*
    v_etape := 'Recherche s''il y a gestion de l''ouverture';
    v_ouverture:=su_bas_gcl_su_lig_par('TYP_UP',p_typ_up,'SU',0,p_colonne => 'ACTION_LIG_PAR_3');
    */

    v_etape := 'Rch ut';
    OPEN c_rch_ut(p_cod_up, p_typ_up);
    FETCH c_rch_ut INTO r_rch_ut;
    IF c_rch_ut%NOTFOUND THEN
        v_ret := 'NON';
    ELSE v_ret := 'OUI';
        p_cod_ut_sup:=  r_rch_ut.cod_ut;
        p_typ_ut_sup:=  r_rch_ut.typ_ut;
    END IF;
    CLOSE c_rch_ut;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'Code UP',
                        p_par_ano_1       => p_cod_up,
                        p_lib_ano_2       => 'Type UP',
                        p_par_ano_2       => p_typ_up,
                        p_lib_ano_3       => 'Grp PSS',
                        p_par_ano_3       => p_grp_pss,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        RETURN 'ERROR';
END;


/*
****************************************************************************
* pc_bas_gen_ut - Génération des UT à partir du plan palette PC_UP
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de générer des UT à partir du plan palette PC_UP
--  __________________________________
--  |                                |
--  |                ______________  |
--  |       P2------|          ___ | |
--  |               |         |   || |
--  |               |   P1----|   || |
--  |               |         |   || |
--  |               |         |   || |
--  |               |         |   || |
--  |               |         |   || |
--  |               |         |   || |
--  |               |         |   || |
--  |               |         |   || |
--  |               |         |---|| |
--  |               |==============| |
--  |                                |---P3
--  |________________________________|
--
--
-- PARAMETRES :
-- ------------
--  xxx
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 03r,21.11.14,pluc    On ne renseigne pas le groupe de process dans le cas 
--                      des créations des Uts de rang 2 et 3 pour ne pas générer
--                      1 UT de niveau sup pour chaque groupe de process.
-- 03q,09.08.14,mnev    Positionne le process et le groupe de process dès la création 
--                      des UT (rang 1, 2 ou 3).
-- 03q,19.02.14,mnev    Init des clés de creation UT rang 1,2 et 3.
-- 03o,11.09.12,alfl    suppression du code= Ajout changement mode_pal des palettes 
--                      complètes et des palettes
--                      auto fermées et qui sont mono - produit
-- 03m,20.07.12,alfl    ajout test du no_dpt pour mise à jour cod_ut_sup des UEE 
-- 03l,03.05.12,mnev    Mise a jour de l'order by
-- 03k,27.09.11,alfl    Gestion de la clé PLAN_MONO_SOC pour la creation de la palette
-- 03j,21.07.11,rbel    Mise à jour information de dénormalisation tournée
-- 03i,23.02.11,mnev    Ajout order by
-- 03h,20.09.10,rbel    Correction curseur lst_up pour remettre grp_pss 
--                      dans le group by comme dans les versions précédentes 
-- 03g,30.09.10,mnev    Ajout changement mode_pal des palettes complètes et des palettes
--                      auto fermées et qui sont mono - produit
-- 03f,08.09.10,mnev    Correction : initialise v_change à chaque fetch 
-- 03e,10.06.10,mnev    Gestion clef v_change. Si on genere une nouvelle UT
--                      de niveau N on doit obligatoirement genere de 
--                      nouvelle UT inférieures !
-- 03d,12.05.10,cmag    Gestion clef MODE_FERM_UT2
-- 03c,04.03.10,mnev    Gestion clef MODE_FERM_UT1
-- 03b,02.02.10,mnev    Corrige recuperation ecart sur depart
--                      (mise a jour des colis)
-- 03a,08.12.09,mnev    Passe no_dpt en paramètre a ut_existe ... pour
--                      assurer la selection d'une UT du bon départ.
-- 02b,27.10.09,mnev    Ajout cod_cnt_up
-- 02a,30.07.09,mnev    Ajout critere no_com
-- 01d,10.12.08,mnev    Correction sur gestion du groupe de process
-- 01c,26.11.08,mnev    Gestion de la différence entre depart plan et
--                      depart colis. Dans ce cas on isole commande sur une
--                      UT P1 de type CMD sur le depart donné par le colis.
-- 01b,21.05.08,mnev    MAJ cod_grp_pss si NULL
-- 01a,25.04.07,xxxx    ...
-- 00a,25.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--  NON

FUNCTION pc_bas_gen_ut (p_cod_verrou pc_ut.lst_fct_lock%TYPE) RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 03q $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_gen_ut';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
	v_session_ora       VARCHAR2(20)  := su_global_pkv.v_no_session_ora;
    err_except          EXCEPTION;
	v_ret               VARCHAR2(100) := NULL;
	v_cod_ut_P1			pc_ut.cod_ut%TYPE;
	v_typ_ut_P1			pc_ut.typ_ut%TYPE;	
	v_cod_ut_P2			pc_ut.cod_ut%TYPE;
	v_typ_ut_P2			pc_ut.typ_ut%TYPE;
	v_cod_ut_P3			pc_ut.cod_ut%TYPE;
	v_typ_ut_P3			pc_ut.typ_ut%TYPE;
	v_cod_verrou  		pc_ut.lst_fct_lock%TYPE;
	v_etat_atv_pc_uee_det VARCHAR2(30);
	v_etat_atv_pc_uee	VARCHAR2(30);
    v_cod_soc           pc_ent_com.cod_soc%TYPE;

    CURSOR c_lst_up (x_cod_verrou           pc_ut.lst_fct_lock%TYPE,
					 x_etat_atv_pc_uee_det  VARCHAR2,
					 x_etat_atv_pc_uee      VARCHAR2) IS
        SELECT uee.no_dpt no_dpt_uee,
              up.cod_up cod_up1, up.typ_up typ_up1,
              up.cod_up_sup cod_up_sup1, up.typ_up_sup typ_up_sup1,
		      up.cod_up_sup, up.typ_up_sup,
              up.cod_up, up.typ_up,up.cod_soc,
              up.sgn_pal_up, up.mode_pal_up, up.typ_pal_up,
              up.cle_rgp_pal_up, up.no_dpt no_dpt_up,
              up.cod_tra, up.cod_tou, up.cod_usn,
              up.cod_ptp_1, up.cod_ptp_2, up.cod_cli,
              up.no_cmd, up.no_com, up.cod_pro, up.cod_va, up.cod_vl,
              up.no_lig_cmd, up.no_ord_ds_tou, up.no_ord_ds_zg,
              up.cod_zg, up.no_var_cfg_pal_up, up.cod_cfg_pal_up,
              up.libre_pc_up_1, up.libre_pc_up_2,
              up.libre_pc_up_3, up.libre_pc_up_4, up.libre_pc_up_5,
              up.usr_lock,up.cod_cnt_up, up.no_ord_up,
              MIN(uee.no_uee) no_uee_min,
              MIN(uee.cod_pss_afc) cod_pss_afc,
              pss.cod_grp_pss
	     FROM su_pss pss, pc_up up, pc_uee uee, pc_uee_det ued
         WHERE up.cod_up = uee.cod_up AND up.typ_up = uee.typ_up
          AND uee.etat_atv_pc_uee = x_etat_atv_pc_uee
	      AND uee.id_session_lock = v_session_ora
	      AND INSTR(uee.lst_fct_lock, ';'||x_cod_verrou||';') > 0
	      AND uee.cod_err_pc_uee IS NULL
	      AND ued.etat_atv_pc_uee_det = x_etat_atv_pc_uee_det
	      AND uee.no_uee = ued.no_uee
	      AND ued.cod_err_pc_uee_det IS NULL
	      AND up.cod_err_pc_up IS NULL
          AND uee.cod_pss_afc = pss.cod_pss
        GROUP BY uee.no_dpt,
                 up.cod_up, up.typ_up,
                 up.cod_up_sup, up.typ_up_sup,
                 up.sgn_pal_up, up.mode_pal_up, up.typ_pal_up,
                 up.cle_rgp_pal_up, up.no_dpt,
                 up.cod_tra, up.cod_tou, up.cod_usn,up.cod_soc,
                 up.cod_ptp_1, up.cod_ptp_2, up.cod_cli,
                 up.no_cmd, up.no_com, up.cod_pro, up.cod_va, up.cod_vl,
                 up.no_lig_cmd, up.no_ord_ds_tou, up.no_ord_ds_zg,
                 up.cod_zg, up.no_var_cfg_pal_up, up.cod_cfg_pal_up,
                 up.libre_pc_up_1, up.libre_pc_up_2,
                 up.libre_pc_up_3, up.libre_pc_up_4, up.libre_pc_up_5,
                 up.usr_lock,up.cod_cnt_up,up.no_ord_up,
                 pss.cod_grp_pss
        ORDER BY uee.no_dpt, up.cod_up_sup, up.typ_up_sup, up.cod_up, up.typ_up, up.no_ord_up;

    r_lst_up     c_lst_up%ROWTYPE;
    r_lst_up_ori c_lst_up%ROWTYPE;

    -- Curseurs sur les colis pour lecture des UT
	CURSOR c_ut (x_cod_verrou   pc_ut.lst_fct_lock%TYPE) IS
	SELECT u.cod_ut_sup cod_ut,
	       u.typ_ut_sup typ_ut,     
		   u.cod_pss_afc,
           ut.cod_ut_sup cod_ut_sup,
           ut.typ_ut_sup typ_ut_sup,
           ut.mode_pal_ut, 
           ut.no_dpt,
           up.etat_up_complete
	FROM pc_uee u, pc_ut ut, pc_up up
	WHERE u.cod_err_pc_uee IS NULL      	 	             AND 	
	      u.id_session_lock = v_session_ora                  AND	
		  INSTR(u.lst_fct_lock,';'||x_cod_verrou||';') > 0   AND
	      u.id_session_lock = v_session_ora
     AND ut.cod_ut = u.cod_ut_sup
     AND ut.typ_ut = u.typ_ut_sup
     AND up.cod_up = ut.cod_up
     AND up.typ_up = ut.typ_up
    GROUP BY u.cod_ut_sup, u.typ_ut_sup, u.cod_pss_afc,
             ut.cod_ut_sup, ut.typ_ut_sup, up.etat_up_complete,
             ut.mode_pal_ut,ut.no_dpt;

    r_ut c_ut%ROWTYPE;

	-- Curseur pour les UP de type P2
	CURSOR c_up2 (x_cod_up PC_UP.cod_up%TYPE,
				  x_typ_up PC_UP.typ_up%TYPE) IS
	SELECT *
	FROM pc_up
	WHERE cod_up = x_cod_up AND typ_up = x_typ_up;
	r_up2 c_up2%ROWTYPE;

	-- Curseur pour les UP de type P3
	CURSOR c_up3 (x_cod_up PC_UP.cod_up%TYPE,
				  x_typ_up PC_UP.typ_up%TYPE) IS
	SELECT *
	FROM pc_up
	WHERE cod_up = x_cod_up AND typ_up = x_typ_up;
	r_up3 c_up3%ROWTYPE;

    -- UEE preparée sur l'UT ? (hors process solde ...)
    CURSOR c_prp (x_cod_ut pc_uee.cod_ut_sup%TYPE,
                  x_typ_ut pc_uee.typ_ut_sup%TYPE,
                  x_etat   NUMBER) IS
    SELECT B.cod_pss_afc
      FROM pc_uee B, su_pss C
    WHERE B.cod_ut_sup = x_cod_ut AND B.typ_ut_sup = x_typ_ut AND 
          su_bas_etat_val_num(B.etat_atv_pc_uee,'PC_UEE') >= x_etat AND 
          B.cod_pss_afc = C.cod_pss AND C.ss_typ_pss <> 'SL';

    r_prp            c_prp%ROWTYPE;

    -- UT supérieure (PC)
    CURSOR c_ut_sup (x_cod_ut_pal1 pc_val_pc.cod_ut_pal1%TYPE,
                     x_typ_ut_pal1 pc_val_pc.typ_ut_pal1%TYPE) IS
    SELECT B.etat_atv_pc_ut, B.dat_reg, B.no_rmp, B.cod_grp_pss, B.cod_pss_afc
      FROM pc_ut B
    WHERE B.cod_ut = x_cod_ut_pal1 AND B.typ_ut = x_typ_ut_pal1;

    r_ut_sup            c_ut_sup%ROWTYPE;
    
    CURSOR c_nb_pro (x_cod_ut   pc_ut.cod_ut%TYPE,
                     x_typ_ut   pc_ut.typ_ut%TYPE) IS
        SELECT COUNT(DISTINCT(d.cod_pro_res||d.cod_va_res||d.cod_vl_res)) nb_pro,
               MIN(u.no_uee) no_uee_min
          FROM pc_uee u, pc_uee_det d
         WHERE u.cod_ut_sup = x_cod_ut
           AND u.typ_ut_sup = x_typ_ut
           AND d.no_uee = u.no_uee;
    
    r_nb_pro            c_nb_pro%ROWTYPE;
    
    CURSOR c_info_uee (x_no_uee   pc_uee.no_uee%TYPE) IS
        SELECT d.cod_pro_res, d.cod_va_res, d.cod_vl_res, l.no_cmd, e.cod_cli
          FROM pc_uee u, pc_uee_det d, pc_lig_com l, pc_ent_com e
         WHERE u.no_uee = x_no_uee
           AND d.no_uee = u.no_uee
           AND l.no_com = d.no_com
           AND l.no_lig_com = d.no_lig_com
           AND e.no_com = l.no_com;
    
    r_info_uee            c_info_uee%ROWTYPE;

    v_no_dpt            pc_up.no_dpt%TYPE;

    v_etat_pal_ut       VARCHAR2(10) := NULL;
    v_mode_ferm_ut      VARCHAR2(10) := NULL;

    -- $MOD,cmag,03d
    v_mode_ferm_ut2     VARCHAR2(10) := NULL;
    v_pc_ut             pc_ut%ROWTYPE;

    r_elm_up            pc_elm_up%ROWTYPE;
    v_cod_cli           pc_ent_com.cod_cli%TYPE;
    v_cod_cli_final     pc_lig_com.cod_cli_final%TYPE;
    v_ctx               su_ctx_pkg.tt_ctx;
    v_change            VARCHAR2(10) := 'NON';
    v_mode_cal_coord_up VARCHAR2(10);
    v_no_msg            su_dia_cubeiq.no_msg_cubeiq%TYPE;

BEGIN

    SAVEPOINT my_pc_bas_gen_ut; -- Pour la gestion de l'exception on fixe un point de rollback.

    v_etape := 'Debut trait';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' ' || v_etape);
    END IF;

    v_cod_verrou  := p_cod_verrou;
    v_etape := 'Recherches des états';
	v_etat_atv_pc_uee_det := su_bas_rch_etat_atv('ORDO_FINALISE','PC_UEE_DET');
	v_etat_atv_pc_uee     := su_bas_rch_etat_atv('ORDO_FINALISE','PC_UEE');
    

    v_etape := 'Rch up. etat_atv_pc_uee_det : ' || v_etat_atv_pc_uee_det || ' etat_atv_pc_uee : ' || v_etat_atv_pc_uee;
	OPEN c_lst_up(v_cod_verrou, v_etat_atv_pc_uee_det, v_etat_atv_pc_uee);
    LOOP
	    FETCH c_lst_up INTO r_lst_up;   			
		EXIT WHEN c_lst_up%NOTFOUND;
		v_ret := 'OK';
        v_etape:='UP trouvée A01';

        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||' ' || v_etape);
        END IF;

        r_lst_up_ori := r_lst_up;
         -- recherche si mono societe
        IF pc_bas_ut_mono_soc(r_lst_up.cod_usn) = 'OUI' THEN
            v_cod_soc:=r_lst_up.cod_soc;
        ELSE
            v_cod_soc:=NULL;
        END IF;

        -- Init des clés de création des UT rang 1,2 et 3
	    v_cod_ut_P1 := NULL;
	    v_typ_ut_P1 := NULL;
	    v_cod_ut_P2 := NULL;
	    v_typ_ut_P2 := NULL;
	    v_cod_ut_P3 := NULL;
	    v_typ_ut_P3 := NULL;

        -- on pense pouvoir suivre le plan ...
        v_change := 'NON';

        v_etape := 'rch mode ferm ut';
        v_etat_pal_ut := pc_ut_pkv.palettisation_ouverte;

        -- controle sur le depart ... entre colis et plan ...
        v_etape := 'controle depart';
        v_no_dpt := r_lst_up.no_dpt_uee;

        IF r_lst_up.no_dpt_uee <> r_lst_up.no_dpt_up THEN
            -- le colis a change de depart par rapport au calcul du plan
            -- Il faut faire une palette commande ...
            v_etape := 'Recherche les informations sur le colis';
            v_ret := pc_bas_rch_info_uee (p_no_uee            =>r_lst_up.no_uee_min,
                                          p_cod_cfg_pal       =>r_lst_up.cod_cfg_pal_up,
                                          p_no_var_cfg_pal    =>r_lst_up.no_var_cfg_pal_up,
                                          p_no_com            =>r_elm_up.no_com,
                                          p_no_cmd            =>r_elm_up.no_cmd,
                                          p_no_lig_cmd        =>r_elm_up.no_lig_cmd,
                                          p_no_dpt            =>r_elm_up.no_dpt,
                                          p_cod_tra           =>r_elm_up.cod_tra,
                                          p_cod_usn           =>r_elm_up.cod_usn,
                                          p_cod_tou           =>r_elm_up.cod_tou,
                                          p_cod_ptp_1         =>r_elm_up.cod_ptp_1,
                                          p_cod_ptp_2         =>r_elm_up.cod_ptp_2,
                                          p_cod_cli           =>v_cod_cli,
                                          p_cod_cli_final     =>v_cod_cli_final,
                                          p_cod_pro           =>r_elm_up.cod_pro,
                                          p_cod_va            =>r_elm_up.cod_va,
                                          p_cod_vl            =>r_elm_up.cod_vl,
                                          p_cod_pss           =>r_elm_up.cod_pss_afc,
                                          p_cle_rgp_pal_1     =>r_elm_up.cle_rgp_pal_1,
                                          p_cle_rgp_pal_2     =>r_elm_up.cle_rgp_pal_2,
                                          p_cle_rgp_pal_3     =>r_elm_up.cle_rgp_pal_3,
                                          p_cod_cfg_pal_1     =>r_elm_up.cod_cfg_pal_1,
                                          p_cod_cfg_pal_2     =>r_elm_up.cod_cfg_pal_2,
                                          p_cod_cfg_pal_3     =>r_elm_up.cod_cfg_pal_3,
                                          p_mode_pal_1        =>r_elm_up.mode_pal_1,
                                          p_mode_pal_2        =>r_elm_up.mode_pal_2,
                                          p_mode_pal_3        =>r_elm_up.mode_pal_3,
                                          p_typ_pal_1         =>r_elm_up.typ_pal_1,
                                          p_typ_pal_2         =>r_elm_up.typ_pal_2,
                                          p_typ_pal_3         =>r_elm_up.typ_pal_3,
                                          p_cod_cnt           =>r_elm_up.cod_cnt,
                                          p_no_ord_ds_tou     =>r_elm_up.no_ord_ds_tou,
                                          p_no_ord_ds_zon_geo =>r_elm_up.no_ord_ds_zg,
                                          p_cod_zon_geo       =>r_elm_up.cod_zg,
                                          p_pds_theo          =>r_elm_up.pds,
                                          p_vol_theo          =>r_elm_up.vol,
                                          p_res               =>r_elm_up.res);
            IF v_ret = 'ERROR' THEN
              RAISE err_except;
            END IF;


            -- C'est une UP de nivau 1
            v_etape := 'set typ_up';
            r_lst_up.cod_up := NULL;
            r_lst_up.typ_up := 'P1';
            r_lst_up.cod_up_sup := NULL;
            r_lst_up.typ_up_sup := NULL;
            r_lst_up.sgn_pal_up := NULL;
            r_lst_up.mode_pal_up := 'CMD';
            r_lst_up.cod_tra    := NULL;
            r_lst_up.cod_tou    := NULL;
            r_lst_up.cod_ptp_1  := NULL;
            r_lst_up.cod_ptp_2  := NULL;
            r_lst_up.cod_cli    := NULL;
            r_lst_up.no_cmd     := NULL;
            r_lst_up.no_lig_cmd := NULL;
            r_lst_up.cod_pro    := NULL;
            r_lst_up.cod_va     := NULL;
            r_lst_up.cod_vl     := NULL;

            v_etape := 'Détermine champs de pc_up f(mode palettisation)';
            v_ret := pc_mod_pal_pkg.pc_bas_gen_up (pr_elm_up       =>r_elm_up,
                                                   p_mode_pal_up   =>'CMD',
                                                   p_cod_tra       =>r_lst_up.cod_tra,
                                                   p_cod_tou       =>r_lst_up.cod_tou,
                                                   p_cod_ptp_1     =>r_lst_up.cod_ptp_1,
                                                   p_cod_ptp_2     =>r_lst_up.cod_ptp_2,
                                                   p_cod_cli       =>r_lst_up.cod_cli,
                                                   p_no_com        =>r_lst_up.no_com,
                                                   p_no_cmd        =>r_lst_up.no_cmd,
                                                   p_no_lig_cmd    =>r_lst_up.no_lig_cmd,
                                                   p_cod_pro       =>r_lst_up.cod_pro,
                                                   p_cod_va        =>r_lst_up.cod_va,
                                                   p_cod_vl        =>r_lst_up.cod_vl);

            IF v_ret <> 'OK' THEN
                RAISE err_except;
            END IF;

            -- $MOD,04a,pluc 
            v_etape := 'gestion coordonnees';
            -- plan avec calcul de coordonnées spatiales?
            v_ret := su_bas_rch_cle_atv_pss(p_cod_pss => r_lst_up.cod_pss_afc,
                                            p_typ_atv => 'POR',
                                            p_cod_cfg => 'MODE_CAL_COORD_UEE',
                                            p_val     => v_mode_cal_coord_up);
            IF v_ret <> 'OK' THEN
                v_etape := 'gestion coordonnees v_ret:' || v_ret;
                RAISE err_except;
            END IF;

            IF v_mode_cal_coord_up = '1' THEN            
                v_etape := 'recalcul coordonnees';

                UPDATE pc_up
                SET etat_up_complete = '0'
                WHERE cod_up = r_lst_up_ori.cod_up
                AND   typ_up = r_lst_up_ori.cod_up;

                INSERT INTO su_dia_cubeiq (no_msg_cubeiq, etat_msg, cod_usn, command_cubeiq, par_cubeIQ_1, par_cubeIQ_2)
                VALUES (SEQ_SU_DIA_CUBEIQ.nextval, '3', r_lst_up_ori.cod_usn, 
                        'ASYNCOPTIMIZE', r_lst_up_ori.typ_up, r_lst_up_ori.cod_up);

            END IF;

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj || 'Recupere difference de depart no_uee:' || r_lst_up.no_uee_min);
            END IF;

            v_cod_err_su_ano := 'PC-UT-006';
            su_bas_cre_ano (p_txt_ano         => 'Différence de depart',
                            p_cod_err_ora_ano => SQLCODE,
                            p_niv_ano         => '3',
                            p_lib_ano_1       => 'no_uee',
                            p_par_ano_1       => r_lst_up.no_uee_min,
                            p_lib_ano_2       => 'no_dpt_uee',
                            p_par_ano_2       => r_lst_up.no_dpt_uee,
                            p_lib_ano_3       => 'no_dpt_up',
                            p_par_ano_3       => r_lst_up.no_dpt_up,
                            p_cod_err_su_ano  => v_cod_err_su_ano,
                            p_nom_obj         => v_nom_obj,
                            p_version         => v_version);

        END IF;

        v_etape := 'controle niveau 2 et 3';
		IF r_lst_up.cod_up_sup IS NOT NULL THEN -- cod_up de la palette d'expédition
            v_etape:='cle PLAN_MONO_SOC';
            OPEN c_up2(r_lst_up.cod_up_sup, r_lst_up.typ_up_sup);
			FETCH c_up2 INTO r_up2;
			
			IF c_up2%FOUND THEN
				-- on a les données de UP pour le niveau P2 (palette d'expédition)
				-- on regarde si le niveau P3 est renseigné :
				IF r_up2.cod_up_sup IS NOT NULL THEN
					-- on a le niveau P3 et on va récupérer les données associé à cet UP

					OPEN c_up3(r_up2.cod_up_sup,r_up2.typ_up_sup);
					FETCH c_up3 INTO r_up3;
					IF c_up3%FOUND THEN

                        v_etape:='recupere donnees UP';
                        IF su_global_pkv.v_niv_dbg >= 6 THEN
                            su_bas_put_debug(v_nom_obj||' ' || v_etape|| ' v_ret ' || v_ret);
                        END IF;

						-- On vérifie que l'UT n'existe pas déjà ou qu'elle n'est pas fermée
						IF v_ret = 'OK' AND
						   pc_bas_ut_existe_et_ouverte(r_up3.cod_up, r_up3.typ_up, NULL, v_no_dpt, v_cod_ut_P3,v_typ_ut_P3) = 'NON' THEN
							-- on va créer l'UT pour l'UP de type P3
							v_etape := 'Création de l''UT pour l''UP de type P3';
                            v_cod_ut_P3:=NULL;

                            v_ret := pc_bas_cre_ut (p_cod_ut => v_cod_ut_P3,
										p_typ_ut => v_typ_ut_P3,
										p_cod_ut_sup => null,
										p_typ_ut_sup => null,
										p_cod_up => r_up3.cod_up,
										p_typ_up => r_up3.typ_up,
										p_etat_pal_ut => v_etat_pal_ut,
										p_no_rmp => null,
										p_no_tav => null,
										p_dat_reg => null,
										p_lib_zon_pal => null,
										p_id_sscc => null,
										p_sgn_pal_ut => r_up3.sgn_pal_up,
										p_mode_pal_ut => r_up3.mode_pal_up,
										p_typ_pal_ut => r_up3.typ_pal_up,
										p_cod_cfg_pal_ut => r_up3.cod_cfg_pal_up,
										p_no_var_cfg_pal_ut => r_up3.no_var_cfg_pal_up,
										p_cle_rgp_pal_ut => r_up3.cle_rgp_pal_up,
										p_no_dpt => v_no_dpt,
										p_cod_tra => r_up3.cod_tra,
										p_cod_tou => r_up3.cod_tou,
										p_cod_usn => r_up3.cod_usn,
                                        p_cod_soc=> v_cod_soc,
										p_cod_ptp_1 => r_up3.cod_ptp_1,
										p_cod_ptp_2 => r_up3.cod_ptp_2,
										p_cod_cli => r_up3.cod_cli,
										p_no_com => r_up3.no_com,
										p_no_cmd => r_up3.no_cmd,
										p_cod_pro => r_up3.cod_pro,
										p_cod_va => r_up3.cod_va,
										p_cod_vl => r_up3.cod_vl,
										p_no_lig_cmd => r_up3.no_lig_cmd,
										p_no_ord_ds_tou => r_up3.no_ord_ds_tou,
										p_no_ord_ds_zg => r_up3.no_ord_ds_zg,
										p_cod_zg => r_up3.cod_zg,
                                        p_cod_grp_pss => NULL,
                                        p_cod_pss_afc => r_lst_up.cod_pss_afc,
										p_libre_pc_ut_1 => r_up3.libre_pc_up_1,
										p_libre_pc_ut_2 => r_up3.libre_pc_up_2,
										p_libre_pc_ut_3 => r_up3.libre_pc_up_3,
										p_libre_pc_ut_4 => r_up3.libre_pc_up_4,
										p_libre_pc_ut_5 => r_up3.libre_pc_up_5,
                                        p_cod_cnt_ut => r_up3.cod_cnt_up,
                                        p_ut_expedition => '0',
										p_usr_lock => r_up3.usr_lock);
							IF v_ret <> 'OK' THEN
								v_cod_err_su_ano := 'PC-UT-003';
								su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
												p_cod_err_ora_ano => SQLCODE,
												p_lib_ano_1       => 'Code de l''UP',
												p_par_ano_1       => r_up3.cod_up,
												p_lib_ano_2       => 'Type de l''UP',
												p_par_ano_2       => r_up3.typ_up,
												p_cod_err_su_ano  => v_cod_err_su_ano,
												p_nom_obj         => v_nom_obj,
												p_version         => v_version);
							END IF;
                            v_change := 'OUI'; -- on a changer la structure ... pour toute la chaine inférieure
						END IF;
					END IF;
					CLOSE c_up3;
				END IF;
			
				-- On vérifie que l'UT n'existe pas déjà ou qu'elle n'est pas fermée
				IF v_ret  = 'OK' AND 
                   (v_change = 'OUI' OR pc_bas_ut_existe_et_ouverte(r_up2.cod_up, r_up2.typ_up, 
                                                                    NULL, v_no_dpt, 
                                                                    v_cod_ut_P2,v_typ_ut_P2) = 'NON') THEN
					-- on va créer l'UT pour l'UP de type P2
					v_etape := 'Création de l''UT pour l''UP de type P2';

                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' ' || v_etape);
                    END IF;

                    v_cod_ut_P2:=NULL;
                    v_ret := pc_bas_cre_ut (p_cod_ut => v_cod_ut_P2,
										p_typ_ut => v_typ_ut_P2,
										p_cod_ut_sup => v_cod_ut_P3,
										p_typ_ut_sup => v_typ_ut_P3,
										p_cod_up => r_up2.cod_up,
										p_typ_up => r_up2.typ_up,
										p_etat_pal_ut => v_etat_pal_ut,
										p_no_rmp => null,
										p_no_tav => null,
										p_dat_reg => null,
										p_lib_zon_pal => null,
										p_id_sscc => null,
										p_sgn_pal_ut => r_up2.sgn_pal_up,
										p_mode_pal_ut => r_up2.mode_pal_up,
										p_typ_pal_ut => r_up2.typ_pal_up,
										p_cod_cfg_pal_ut => r_up2.cod_cfg_pal_up,
										p_cle_rgp_pal_ut => r_up2.cle_rgp_pal_up,
										p_no_dpt => v_no_dpt,
										p_cod_tra => r_up2.cod_tra,
										p_cod_tou => r_up2.cod_tou,
										p_cod_usn => r_up2.cod_usn,
                                        p_cod_soc=>v_cod_soc,
										p_cod_ptp_1 => r_up2.cod_ptp_1,
										p_cod_ptp_2 => r_up2.cod_ptp_2,
										p_cod_cli => r_up2.cod_cli,
										p_no_com => r_up2.no_com,
										p_no_cmd => r_up2.no_cmd,
										p_cod_pro => r_up2.cod_pro,
										p_cod_va => r_up2.cod_va,
										p_cod_vl => r_up2.cod_vl,
										p_no_lig_cmd => r_up2.no_lig_cmd,
										p_no_ord_ds_tou => r_up2.no_ord_ds_tou,
										p_no_ord_ds_zg => r_up2.no_ord_ds_zg,
										p_cod_zg => r_up2.cod_zg,
                                        p_cod_grp_pss => NULL,
                                        p_cod_pss_afc => r_lst_up.cod_pss_afc,
										p_libre_pc_ut_1 => r_up2.libre_pc_up_1,
										p_libre_pc_ut_2 => r_up2.libre_pc_up_2,
										p_libre_pc_ut_3 => r_up2.libre_pc_up_3,
										p_libre_pc_ut_4 => r_up2.libre_pc_up_4,
										p_libre_pc_ut_5 => r_up2.libre_pc_up_5,
                                        p_cod_cnt_ut => r_up2.cod_cnt_up,
                                        p_ut_expedition => '0',
										p_usr_lock => r_up2.usr_lock);
					IF v_ret <> 'OK' THEN
						v_cod_err_su_ano := 'PC-UT-002';
                        su_bas_cre_ano (p_txt_ano => 'EXCEPTION : ' || v_etape,
												p_cod_err_ora_ano => SQLCODE,
												p_lib_ano_1       => 'Code de l''UP',
												p_par_ano_1       => r_up2.cod_up,
												p_lib_ano_2       => 'Type de l''UP',
												p_par_ano_2       => r_up2.typ_up,
												p_cod_err_su_ano  => v_cod_err_su_ano,
												p_nom_obj         => v_nom_obj,
												p_version         => v_version);
					END IF;
                    v_change := 'OUI'; -- on a changer la structure ... pour toute la chaine inférieure
				END IF;				
			END IF;	
			CLOSE c_up2;
        END IF;
			
		-- On vérifie que l'UT n'existe pas déjà ou qu'elle n'est pas fermée (palette de tri)		
        IF v_ret = 'OK' AND 
            (
            v_change = 'OUI' OR
            r_lst_up.cod_up IS NULL OR
			pc_bas_ut_existe_et_ouverte(r_lst_up.cod_up, r_lst_up.typ_up, r_lst_up.cod_grp_pss, v_no_dpt, v_cod_ut_P1, v_typ_ut_P1) = 'NON' 
            ) THEN
            -- on va créer l'UT pour l'UP de type P1
			v_etape := 'Création de l''UT pour l''UP de type P1';

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' ' || v_etape);
            END IF;

            v_cod_ut_P1:=NULL;
            v_ret := pc_bas_cre_ut (p_cod_ut => v_cod_ut_P1,
                                    p_typ_ut => v_typ_ut_P1,
                                    p_cod_ut_sup => v_cod_ut_P2,
                                    p_typ_ut_sup => v_typ_ut_P2,
                                    p_cod_up => r_lst_up.cod_up,
                                    p_typ_up => r_lst_up.typ_up,
									p_etat_pal_ut => v_etat_pal_ut,
                                    p_no_rmp => null,
                                    p_no_tav => null,
                                    p_dat_reg => null,
                                    p_lib_zon_pal => null,
                                    p_id_sscc => null,
                                    p_sgn_pal_ut => r_lst_up.sgn_pal_up,
                                    p_mode_pal_ut => r_lst_up.mode_pal_up,
                                    p_typ_pal_ut => r_lst_up.typ_pal_up,
                                    p_cod_cfg_pal_ut => r_lst_up.cod_cfg_pal_up,
									p_cle_rgp_pal_ut => r_lst_up.cle_rgp_pal_up,
                                    p_no_dpt => v_no_dpt,
                                    p_cod_tra => r_lst_up.cod_tra,
                                    p_cod_tou => r_lst_up.cod_tou,
                                    p_cod_usn => r_lst_up.cod_usn,
                                    p_cod_soc=>v_cod_soc,
                                    p_cod_ptp_1 => r_lst_up.cod_ptp_1,
                                    p_cod_ptp_2 => r_lst_up.cod_ptp_2,
                                    p_cod_cli => r_lst_up.cod_cli,
                                    p_no_com => r_lst_up.no_com,
                                    p_no_cmd => r_lst_up.no_cmd,
                                    p_cod_pro => r_lst_up.cod_pro,
                                    p_cod_va => r_lst_up.cod_va,
                                    p_cod_vl => r_lst_up.cod_vl,
                                    p_no_lig_cmd => r_lst_up.no_lig_cmd,
                                    p_no_ord_ds_tou => r_lst_up.no_ord_ds_tou,
                                    p_no_ord_ds_zg => r_lst_up.no_ord_ds_zg,
                                    p_cod_zg => r_lst_up.cod_zg,
                                    p_no_var_cfg_pal_ut => r_lst_up.no_var_cfg_pal_up,
                                    p_cod_grp_pss => r_lst_up.cod_grp_pss,
                                    p_cod_pss_afc => r_lst_up.cod_pss_afc,
                                    p_libre_pc_ut_1 => r_lst_up.libre_pc_up_1,
                                    p_libre_pc_ut_2 => r_lst_up.libre_pc_up_2,
                                    p_libre_pc_ut_3 => r_lst_up.libre_pc_up_3,
                                    p_libre_pc_ut_4 => r_lst_up.libre_pc_up_4,
                                    p_libre_pc_ut_5 => r_lst_up.libre_pc_up_5,
                                    p_cod_cnt_ut => r_lst_up.cod_cnt_up,
                                    p_ut_expedition => '0',
                                    p_usr_lock => r_lst_up.usr_lock);
            IF v_ret <> 'OK' THEN
				v_cod_err_su_ano := 'PC-UT-001';
                su_bas_cre_ano (p_txt_ano => 'EXCEPTION : ' || v_etape,
								p_cod_err_ora_ano => SQLCODE,
								p_lib_ano_1       => 'Code de l''UP',
								p_par_ano_1       => r_lst_up.cod_up,
								p_lib_ano_2       => 'Type de l''UP',
								p_par_ano_2       => r_lst_up.typ_up,
                                p_lib_ano_3       => 'Usine',
    							p_par_ano_3       => r_lst_up.cod_usn,
    							p_cod_err_su_ano  => v_cod_err_su_ano,
								p_nom_obj         => v_nom_obj,
								p_version         => v_version);
			END IF;
            v_change := 'OUI'; -- on a changer la structure ... pour toute la chaine inférieure
		END IF;	

		IF v_ret = 'OK' THEN
            -- --------------------------------------------------------------
            -- Si l'UT est déjà régulée
            -- alors il faut descendre les infos de régulation dans les colis
            -- --------------------------------------------------------------
            IF su_global_pkv.v_niv_dbg >= 3 THEN
                su_bas_put_debug(v_nom_obj||' ' || 'CodUt:' || v_cod_ut_P1 || 'TypUt:' || v_typ_ut_P1);
            END IF;
            v_etape := 'open c_ut_sup';
            OPEN c_ut_sup (v_cod_ut_P1, v_typ_ut_P1);
            FETCH c_ut_sup INTO r_ut_sup;
            IF c_ut_sup%FOUND THEN

                -- si le groupe process est NULL alors le remettre a jour
                -- cas de l'interruption qui peut dans certaines situations
                -- remettre le groupe de process à NULL sur une UT n'ayant plus
                -- aucun colis ordonnancé.

                v_etape:='maj des UT';
                IF r_ut_sup.cod_grp_pss IS NULL THEN
                    v_etape := 'MAJ groupe process sur UT';
                    UPDATE pc_ut SET
                        cod_grp_pss = r_lst_up.cod_grp_pss
                    WHERE cod_ut = v_cod_ut_P1 AND typ_ut = v_typ_ut_P1;

                    r_ut_sup.cod_grp_pss := r_lst_up.cod_grp_pss;
                END IF;

                v_etape:='UT regulee ?';
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' ' || v_etape);
                END IF;
                --
                -- L'UT existe ... verification de la regulation
                --
                IF pc_bas_is_ut_regulee (p_cod_ut => v_cod_ut_P1,
                                         p_typ_ut => v_typ_ut_P1,
                                         p_cod_pss => r_ut_sup.cod_pss_afc,
                                         p_etat_ut => r_ut_sup.etat_atv_pc_ut) = 'REGUL_OK' THEN
                    -- L'UT est déjà regulée ...
                    -- Il faut en tenir compte pour le colis
                    v_etape := 'MAJ infos UT ' || v_cod_ut_P1 || v_typ_ut_P1 ||
                               ' regulée sur colis';
                    IF su_global_pkv.v_niv_dbg >= 6 THEN
                        su_bas_put_debug(v_nom_obj||' ' || v_etape);
                    END IF;

                    UPDATE pc_uee SET
                        dat_reg         = r_ut_sup.dat_reg,
                        no_reg          = TO_CHAR(r_ut_sup.dat_reg,'SSSSS'),
                        no_rmp          = r_ut_sup.no_rmp,
                        etat_atv_pc_uee = su_bas_rch_etat_atv('REGULATION','PC_UEE'),
                        cod_ut_sup      = v_cod_ut_P1,
                        typ_ut_sup      = v_typ_ut_P1 
                        
                    WHERE
					    cod_up          = NVL(r_lst_up.cod_up,r_lst_up_ori.cod_up) AND
					    typ_up          = NVL(r_lst_up.typ_up,r_lst_up_ori.typ_up) AND
                        etat_atv_pc_uee = v_etat_atv_pc_uee             AND
                        no_dpt=v_no_dpt AND
                        id_session_lock = v_session_ora                 AND
                        INSTR(lst_fct_lock, ';'||v_cod_verrou||';') > 0 AND
                        cod_err_pc_uee IS NULL                          AND
						EXISTS (SELECT 1 FROM pc_uee_det
	                            WHERE  pc_uee_det.no_uee = pc_uee.no_uee                       AND
			                           pc_uee_det.etat_atv_pc_uee_det =  v_etat_atv_pc_uee_det AND
									   pc_uee_det.cod_err_pc_uee_det IS NULL) AND
                        su_bas_gcl_su_pss (pc_uee.cod_pss_afc, 'COD_GRP_PSS') = r_lst_up.cod_grp_pss;
                ELSE
                    v_etape := 'MAJ infos UT non-regulée sur colis';
                    UPDATE pc_uee SET
                        cod_ut_sup = v_cod_ut_P1,
                        typ_ut_sup = v_typ_ut_P1,
                        cod_up     = r_lst_up.cod_up,
                        typ_up     = DECODE(r_lst_up.cod_up,NULL,NULL,r_lst_up.typ_up)
                    WHERE cod_up = NVL(r_lst_up.cod_up,r_lst_up_ori.cod_up) AND 
                          typ_up = NVL(r_lst_up.typ_up,r_lst_up_ori.typ_up) AND
                          etat_atv_pc_uee = v_etat_atv_pc_uee AND
                          no_dpt=v_no_dpt AND
                          id_session_lock = v_session_ora AND
                          INSTR(lst_fct_lock, ';'||v_cod_verrou||';') > 0 AND
                          cod_err_pc_uee IS NULL AND
                          su_bas_gcl_su_pss (pc_uee.cod_pss_afc, 'COD_GRP_PSS') = r_lst_up.cod_grp_pss;
                END IF;

                v_etape:='UEE preparée ?';
                IF su_global_pkv.v_niv_dbg >= 6 THEN
                    su_bas_put_debug(v_nom_obj||' ' || v_etape || ' MAJ de ' || SQL%ROWCOUNT || ' UEE');
                END IF;
                --
                -- verification s'il existe une UEE préparée
                --
                v_etape := 'controle si UEE preparée';
                OPEN c_prp (v_cod_ut_P1, v_typ_ut_P1, su_bas_etat_val_num('PREPA_AVEC_QTE','PC_UEE'));
                FETCH c_prp INTO r_prp;
                IF c_prp%FOUND THEN
                    v_etape := 'MAJ process sur UT';
                    UPDATE pc_ut SET
                        cod_pss_afc = r_prp.cod_pss_afc
                    WHERE cod_ut = v_cod_ut_P1 AND typ_ut = v_typ_ut_P1;
                END IF;
                CLOSE c_prp;
                --
                -- Controle sur pc_val_pc ...
                -- Cas d'une palettisation après préparation.
                --
                v_etape := 'MAJ des val_pc';
                UPDATE pc_val_pc SET
                    cod_ut_pal1 = v_cod_ut_P1,
                    typ_ut_pal1 = v_typ_ut_P1 
                WHERE pc_val_pc.no_uee IN (SELECT u.no_uee 
                                           FROM pc_uee u 
                                           WHERE u.cod_ut_sup = v_cod_ut_P1 AND u.typ_ut_sup = v_typ_ut_P1);
            ELSE
                NULL;
            END IF;
            CLOSE c_ut_sup;

		ELSE  -- => v_ret <> 'OK
           -- On va en exception
           RAISE err_except;
		END IF;   		

    END LOOP;	
    CLOSE c_lst_up;

    v_etape := 'LOOP sur ut';
    IF su_global_pkv.v_niv_dbg >= 6 THEN
        su_bas_put_debug(v_nom_obj || v_etape);
    END IF;
	OPEN c_ut(v_cod_verrou);
    LOOP
        FETCH c_ut INTO r_ut;
		EXIT WHEN c_ut%NOTFOUND;
				
        v_etape := 'rch mode ferm ut';
        v_ret := su_bas_rch_cle_atv_pss(p_cod_pss         =>r_ut.cod_pss_afc,
                                        p_typ_atv         =>'ORD',
                                        p_cod_cfg         =>'MODE_FERM_UT1',
                                        p_val             =>v_mode_ferm_ut);
        IF v_ret = 'ERROR' THEN
            RAISE err_except;
        END IF;
       
       
        -- 11.09.2012   ticket #21768
        -- on enleve ce bout de code car on ne voit plus l'impact sur les etiquette colis
        -- et cela pose un problème pour la fusion de 2 palettes produits
        
        -- Pour les palettes complètes et toutes celles qui sont fermées dès l'ordo
        -- on peut vérifier si elles sont mono-produit et si c'est le cas faire le
        -- changement de mode de palettisation pour les éditions futures
        --  IF r_ut.etat_up_complete = '1' OR NVL(v_mode_ferm_ut,'1') = '2' THEN
        --     v_etape := 'Vérification nb référence pro';
        --     OPEN c_nb_pro(r_ut.cod_ut, r_ut.typ_ut);
        --     FETCH c_nb_pro INTO r_nb_pro;
        --     IF c_nb_pro%FOUND AND r_nb_pro.nb_pro = 1 THEN
                
        --         OPEN c_info_uee (r_nb_pro.no_uee_min);
        --         FETCH c_info_uee INTO r_info_uee;
        --         CLOSE c_info_uee;
                
        --         v_etape := 'MAJ mode_pal_ut';
        --         UPDATE pc_ut SET 
        --             mode_pal_ut = 'PRO',
        --             typ_pal_ut ='STD',
        --             no_cmd = r_info_uee.no_cmd,
        --             cod_pro = r_info_uee.cod_pro_res, 
        --             cod_va = r_info_uee.cod_va_res,
        --             cod_vl = r_info_uee.cod_vl_res,
        --             cod_cli = r_info_uee.cod_cli                    
        --         WHERE cod_ut = r_ut.cod_ut AND typ_ut = r_ut.typ_ut;
                
        --     END IF;
        --     CLOSE c_nb_pro;        
        -- END IF;

        -- Mise à jour des libelles tournée denormalisés
        v_etape := 'Maj info tou pal_sup ' || r_ut.cod_ut;
        v_ret := pc_bas_maj_tou_def_from_ut (p_cod_ut => r_ut.cod_ut,
                                             p_typ_ut => r_ut.typ_ut,
                                             p_mode_pal_ut => r_ut.mode_pal_ut,
                                             p_no_dpt => r_ut.no_dpt);

        -- si on doit fermer l'UT on ferme !!!
        IF NVL(v_mode_ferm_ut,'1') = '2' THEN

            IF su_global_pkv.v_niv_dbg >= 6 THEN
                su_bas_put_debug(v_nom_obj||' ' || 'UT:' || r_ut.cod_ut || ' ' || r_ut.typ_ut  || ' PSS:' || r_ut.cod_pss_afc);
            END IF;

            v_etape := 'MAJ etat_pal_ut';
            UPDATE pc_ut SET 
                etat_pal_ut  = '0'
            WHERE cod_ut = r_ut.cod_ut AND typ_ut = r_ut.typ_ut;
        END IF;

        --$MOD,cmag,03d
        v_etape := 'Test cod_ut_sup';
        IF r_ut.cod_ut_sup IS NOT NULL AND r_ut.typ_ut_sup IS NOT NULL THEN
            --
            -- controle de l'UT mere
            --
            v_etape := 'test et ferme ut2';
            v_pc_ut := su_bas_grw_pc_ut(p_cod_ut => r_ut.cod_ut_sup, 
                                        p_typ_ut => r_ut.typ_ut_sup);

            v_ret := pc_afu_pkg.pc_bas_test_et_ferme_ut(p_cod_ut => v_pc_ut.cod_ut,
                                                        p_typ_ut => v_pc_ut.typ_ut,
                                                        p_cod_up => v_pc_ut.cod_up,
                                                        p_typ_up => v_pc_ut.typ_up,
                                                        p_cod_pss => r_ut.cod_pss_afc,
                                                        p_mode_app => 'ORD');
                                                        
            -- Mise à jour des libelles tournée denormalisés
            v_etape := 'Maj info tou pal_sup ' || v_pc_ut.cod_ut;
            v_ret := pc_bas_maj_tou_def_from_ut (p_cod_ut => v_pc_ut.cod_ut,
                                                 p_typ_ut => v_pc_ut.typ_ut,
                                                 p_mode_pal_ut => v_pc_ut.mode_pal_ut,
                                                 p_no_dpt => v_pc_ut.no_dpt);
        END IF;
		
    END LOOP;
	CLOSE c_ut;
	
    RETURN 'OK';

EXCEPTION
    WHEN OTHERS THEN
	    IF c_lst_up%ISOPEN THEN
		    CLOSE c_lst_up;
	    END IF;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => '',
                        p_par_ano_1       => '',
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        ROLLBACK TO my_pc_bas_gen_ut;

        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
	
END;

/*
****************************************************************************
* pc_bas_gen_cod_ut - Génère un code UT à partir d'une séquence
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de génèrer un code UT à partir d'une séquence
--
-- PARAMETRES :
-- ------------
--  p_typ_ut => permettre de générer des séquence selon le type de l'UT
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
--
-- 01b,10.05.10,rbel    Correction calcul cod_ut avec ut_sup
-- 01a,25.04.07,xxxx    ...
-- 00a,25.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_gen_cod_ut (p_cod_up        PC_UP.cod_up%TYPE,
                            p_typ_up        PC_UP.typ_up%TYPE,
                            p_typ_ut	    PC_UT.typ_ut%TYPE,
                            p_cod_usn       PC_UT.cod_usn%TYPE,
                            p_cod_ut_sup    pc_ut.cod_ut_sup%TYPE DEFAULT NULL,
                            p_typ_ut_sup    pc_ut.typ_ut_sup%TYPE DEFAULT NULL)  RETURN VARCHAR2
IS
    v_version           su_ano_his.version%TYPE := '@(#) VERSION 01b $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_gen_cod_ut';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := NULL;
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;

    v_make_cod_ut       BOOLEAN:=FALSE;
    v_gestion_indice    VARCHAR2(10);

    -- recherche des ut par up
    CURSOR c_ut_by_up IS
    SELECT cod_ut
      FROM pc_ut
     WHERE cod_up=p_cod_up
       AND typ_up=p_typ_up
     ORDER BY cod_ut desc;

    r_ut_by_up          c_ut_by_up%ROWTYPE;

    -- recherche des ut par ut sup
    CURSOR c_ut_by_ut_sup IS
    SELECT cod_ut
      FROM pc_ut
     WHERE cod_ut_sup=p_cod_ut_sup
       AND typ_ut_sup=p_typ_ut_sup
     ORDER BY cod_ut desc;

    r_ut_by_ut_sup      c_ut_by_ut_sup%ROWTYPE;

BEGIN

    v_etape := 'Debut Trait:';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : cod_up = '    || p_cod_up
                                  ||' : typ_up = '    || p_typ_up
                                  ||' : typ_ut = '    || p_typ_ut
                                  ||' : cod_usn = '   || p_cod_usn
                                  ||' : cod_ut_sup = '|| p_cod_ut_sup
                                  ||' : typ_ut_sup = '|| p_typ_ut_sup);
    END IF;

    IF p_typ_up IS NOT NULL THEN
        v_etape := 'Recherche s''il y a une gestion du n° d''UT avec indice à appliquer';
        v_gestion_indice:=su_bas_gcl_su_lig_par('TYP_UP',p_typ_up,'SU',0,p_colonne => 'ACTION_LIG_PAR_3');
        IF v_gestion_indice ='1' THEN
            IF p_cod_ut_sup IS NULL THEN
                v_etape := 'Recherche s''il y a une UT avec le même code UP';
                OPEN c_ut_by_up;
                FETCH c_ut_by_up INTO r_ut_by_up;
                IF c_ut_by_up%FOUND THEN
                    v_ret := substr(r_ut_by_up.cod_ut,0,instr(r_ut_by_up.cod_ut,'.')) || trim(to_char(to_number(substr(r_ut_by_up.cod_ut,instr(r_ut_by_up.cod_ut,'.')+1,length(r_ut_by_up.cod_ut)))+1,'00'));
                    v_make_cod_ut:=FALSE;
                ELSE
                    v_make_cod_ut:=TRUE;
                END IF;
                CLOSE c_ut_by_up;
            ELSE
                v_etape := 'Recherche s''il y a une UT avec le même code UT sup';
                OPEN c_ut_by_ut_sup;
                FETCH c_ut_by_ut_sup INTO r_ut_by_ut_sup;
                IF c_ut_by_ut_sup%FOUND THEN
                    --v_ret := to_char(to_number(substr(r_ut_by_ut_sup.cod_ut,instr(r_ut_by_ut_sup.cod_ut,'.')+1,length(r_ut_by_ut_sup.cod_ut)))+1,'00');
                    v_ret := substr(r_ut_by_ut_sup.cod_ut,0,instr(r_ut_by_ut_sup.cod_ut,'.')) || trim(to_char(to_number(substr(r_ut_by_ut_sup.cod_ut,instr(r_ut_by_ut_sup.cod_ut,'.')+1,length(r_ut_by_ut_sup.cod_ut)))+1,'00'));
                    v_make_cod_ut:=FALSE;
                ELSE
                    v_make_cod_ut:=TRUE;
                END IF;
                CLOSE c_ut_by_ut_sup;
            END IF;
        ELSE
            v_make_cod_ut:=TRUE;
        END IF;
    ELSE
        v_make_cod_ut    := TRUE;
        v_gestion_indice := '0';    -- NON
    END IF;

    -- Recherche du code UT
    IF v_make_cod_ut THEN
        v_etape := 'Recherche du code UT';
        v_ret:= se_bas_make_cod_ut (p_typ_ut    =>p_typ_ut,
                                    p_cod_usn   =>p_cod_usn);

        IF v_gestion_indice='1' THEN
            v_ret:=  v_ret||'.01';
        END IF;
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        IF c_ut_by_up%ISOPEN THEN
		    CLOSE c_ut_by_up;
	    END IF;

        IF c_ut_by_ut_sup%ISOPEN THEN
		    CLOSE c_ut_by_ut_sup;
	    END IF;
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'p_cod_up',
                        p_par_ano_1       => p_cod_up,
                        p_lib_ano_2       => 'p_typ_up',
                        p_par_ano_2       => p_typ_up,
                        p_lib_ano_3       => 'p_typ_ut',
                        p_par_ano_3       => p_typ_ut,
                        p_lib_ano_4       => 'p_cod_usn',
                        p_par_ano_4       => p_cod_usn,
                        p_lib_ano_5       => 'p_cod_ut_sup',
                        p_par_ano_5       => p_cod_ut_sup,
                        p_lib_ano_6       => 'p_typ_ut_sup',
                        p_par_ano_6       => p_typ_ut_sup,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;


/*
****************************************************************************
* pc_bas_cre_ut - Création des UT
*/
-- DESCRIPTION :
-- -------------
-- Cette fonction permet de faire une insertion dans la table PC_UT
--
-- PARAMETRES :
-- ------------
-- Tous les paramètres nécessaire à su_bas_ins_pc_ut
-- p_cod_ut et p_typ_ut sont des OUT afin de pouvoir récupérer le cod_ut et
-- typ_ut créer
-- ils sont passés à vide à la fonction si on veut generer un nouveau cod_ut
-- si p_cod_ut  NOT NULL on impose le cod_ut
--
-- HISTORIQUE DES MODIFICATIONS :
-- -------------------------------------------------------------------------
-- Ver,Date    ,Auteur  Description
-- -------------------------------------------------------------------------
-- 04a,06.02.12,mnev    ajout colonne dat_exp_ini
-- 03a,28.09.11,alfl    gestion du cod_soc
-- 02d,14.12.10,alfl    gestion du cod_cnt_ut
-- 02c,05.06.08,mnev    ajout nouvelles colonnes + init de la tare si NULL
-- 02b,05.06.08,mnev    maj du code contenant dans se_ut
-- 02a,16.07.07,alfl    on peut imposer le cod_ut
-- 01a,25.04.07,xxxx    ...
-- 00a,25.04.07,GENPRG  version 2.10
-- -------------------------------------------------------------------------
--
-- RETOUR :
-- --------
--  OK ou ERROR ou code erreur
--
-- COMMIT :
-- --------
--   NON

FUNCTION pc_bas_cre_ut (p_cod_ut       IN OUT        PC_UT.COD_UT%TYPE ,
					p_typ_ut           IN OUT        PC_UT.TYP_UT%TYPE ,
					p_cod_ut_sup                     PC_UT.COD_UT_SUP%TYPE DEFAULT NULL,
					p_typ_ut_sup                     PC_UT.TYP_UT_SUP%TYPE DEFAULT NULL,
					p_cod_up                         PC_UT.COD_UP%TYPE DEFAULT NULL,
					p_typ_up                         PC_UT.TYP_UP%TYPE DEFAULT NULL,
					p_etat_pal_ut                    PC_UT.ETAT_PAL_UT%TYPE DEFAULT NULL,
					p_no_rmp		                 PC_UT.NO_RMP%TYPE DEFAULT NULL,
					p_no_tav		                 PC_UT.NO_TAV%TYPE DEFAULT NULL,
					p_dat_reg                        PC_UT.DAT_REG%TYPE DEFAULT NULL,
					p_lib_zon_pal                    PC_UT.LIB_ZON_PAL%TYPE DEFAULT NULL,
					p_id_sscc                        PC_UT.ID_SSCC%TYPE DEFAULT NULL,
					p_sgn_pal_ut                     PC_UT.SGN_PAL_UT%TYPE DEFAULT NULL,
					p_mode_pal_ut                    PC_UT.MODE_PAL_UT%TYPE DEFAULT NULL,
					p_typ_pal_ut                     PC_UT.TYP_PAL_UT%TYPE DEFAULT NULL,
					p_cod_cfg_pal_ut                 PC_UT.COD_CFG_PAL_UT%TYPE DEFAULT NULL,
					p_no_var_cfg_pal_ut              PC_UT.NO_VAR_CFG_PAL_UT%TYPE DEFAULT NULL,
					p_cle_rgp_pal_ut                 PC_UT.CLE_RGP_PAL_UT%TYPE DEFAULT NULL,
					p_no_dpt                         PC_UT.NO_DPT%TYPE DEFAULT NULL,
					p_cod_tra                        PC_UT.COD_TRA%TYPE DEFAULT NULL,
					p_cod_tou                        PC_UT.COD_TOU%TYPE DEFAULT NULL,
					p_cod_usn                        PC_UT.COD_USN%TYPE DEFAULT NULL,
                    p_cod_soc                        PC_ENT_COM.COD_SOC%TYPE DEFAULT NULL,
					p_cod_ptp_1                      PC_UT.COD_PTP_1%TYPE DEFAULT NULL,
					p_cod_ptp_2                      PC_UT.COD_PTP_2%TYPE DEFAULT NULL,
					p_cod_cli                        PC_UT.COD_CLI%TYPE DEFAULT NULL,
					p_no_com                         PC_UT.NO_COM%TYPE DEFAULT NULL,
					p_no_cmd                         PC_UT.NO_CMD%TYPE DEFAULT NULL,
					p_cod_pro                        PC_UT.COD_PRO%TYPE DEFAULT NULL,
					p_cod_va                         PC_UT.COD_VA%TYPE DEFAULT NULL,
					p_cod_vl                         PC_UT.COD_VL%TYPE DEFAULT NULL,
					p_no_lig_cmd                     PC_UT.NO_LIG_CMD%TYPE DEFAULT NULL,
					p_no_ord_ds_tou                  PC_UT.NO_ORD_DS_TOU%TYPE DEFAULT NULL,
					p_no_ord_ds_zg                   PC_UT.NO_ORD_DS_ZG%TYPE DEFAULT NULL,
					p_cod_zg                         PC_UT.COD_ZG%TYPE DEFAULT NULL,
					p_etat_atv_pc_ut                 PC_UT.ETAT_ATV_PC_UT%TYPE DEFAULT NULL,
					p_qte_atv                        PC_UT.QTE_ATV%TYPE DEFAULT NULL,
					p_qte_ref_atv                    PC_UT.QTE_REF_ATV%TYPE DEFAULT NULL,
					p_cod_pss_afc                    PC_UT.COD_PSS_AFC%TYPE DEFAULT NULL,
                    p_cod_grp_pss                    PC_UT.COD_GRP_PSS%TYPE DEFAULT NULL,
					p_cod_err_pc_ut                  PC_UT.COD_ERR_PC_UT%TYPE DEFAULT NULL,
					p_id_session_lock                PC_UT.ID_SESSION_LOCK%TYPE DEFAULT NULL,
					p_lst_fct_lock                   PC_UT.LST_FCT_LOCK%TYPE DEFAULT NULL,
					p_dat_lock                       PC_UT.DAT_LOCK%TYPE DEFAULT NULL,
					p_ope_lock                       PC_UT.OPE_LOCK%TYPE DEFAULT NULL,
					p_libre_pc_ut_1                  PC_UT.LIBRE_PC_UT_1%TYPE DEFAULT NULL,
					p_libre_pc_ut_2                  PC_UT.LIBRE_PC_UT_2%TYPE DEFAULT NULL,
					p_libre_pc_ut_3                  PC_UT.LIBRE_PC_UT_3%TYPE DEFAULT NULL,
					p_libre_pc_ut_4                  PC_UT.LIBRE_PC_UT_4%TYPE DEFAULT NULL,
					p_libre_pc_ut_5                  PC_UT.LIBRE_PC_UT_5%TYPE DEFAULT NULL,
					p_usr_lock 						 PC_UT.USR_LOCK%TYPE DEFAULT NULL,
                    p_cod_mag_loc                    SE_UT.cod_mag_loc%TYPE DEFAULT NULL,
                    p_cod_emp_loc                    SE_UT.cod_emp_loc%TYPE DEFAULT NULL,
                    p_cod_cnt_ut                     PC_UT.cod_cnt_ut%TYPE DEFAULT NULL,
                    p_tare_ut                        PC_UT.tare_ut%TYPE DEFAULT NULL,
                    p_ut_expedition                  PC_UT.ut_expedition%TYPE DEFAULT NULL)
					RETURN VARCHAR2
IS

    v_version           su_ano_his.version%TYPE := '@(#) VERSION 04a $Revision$';
    v_nom_obj           su_ano_his.nom_obj%TYPE := 'pc_bas_cre_ut';
    v_etape             su_ano_his.txt_ano%TYPE := 'Declare';
    v_cod_err_su_ano    su_ano_his.cod_err_su_ano%TYPE := 'PC-UT-005';
    err_except          EXCEPTION;
    v_ret               VARCHAR2(100) := NULL;
	v_id_sscc 			VARCHAR2(30);
	v_cb_ut             VARCHAR2(50);
    v_add_ctx           BOOLEAN;
    v_ctx               su_ctx_pkg.tt_ctx;

    CURSOR c_cpt(x_cod_ut  pc_ut.cod_ut%TYPE,
				 x_typ_ut  pc_ut.typ_ut%TYPE) IS
        SELECT count(*) cpt
        FROM pc_ut
        WHERE cod_ut = x_cod_ut AND typ_ut = p_typ_ut;
    r_cpt c_cpt%ROWTYPE;

    vr_ut               se_ut%ROWTYPE;
	v_debut             TIMESTAMP;
	v_debut_tot         TIMESTAMP;
    v_tare_ut           su_cnt.tare_std%TYPE := NULL;
    v_cod_cnt_ut        se_ut.cod_cnt%TYPE;
    v_dat_exp           pc_ut.dat_exp_ini%TYPE := NULL;

BEGIN

    SAVEPOINT my_pc_bas_cre_ut;  -- Pour la gestion de l'exception on fixe un point de rollback.

    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||'*** BEGIN T=0');
        v_debut_tot := SYSTIMESTAMP;
        v_debut     := v_debut_tot;
    END IF;

    v_etape := 'Trace';
    IF su_global_pkv.v_niv_dbg >= 3 THEN
		su_bas_put_debug(v_nom_obj||' : typ_ut=' || p_typ_ut);
    END IF;
	
    IF p_typ_ut IS NULL THEN
        -- On va déterminer le type de l'UT selon le type de l'UP
	    v_etape  :='On recherche le type de l''UT selon le type de l''UP';
        p_typ_ut:=su_bas_gcl_su_lig_par(p_nom_par   => 'TYP_UP',
                                        p_par       => p_typ_up,
                                        p_cod_module=> 'SU',
                                        p_etat_spec => '0',
                                        p_colonne   => 'ACTION_LIG_PAR_2');
    END IF;

    IF su_global_pkv.v_niv_dbg >= 3 THEN
        su_bas_put_debug(v_nom_obj||' : cod_up=' || p_cod_up || ' ' || p_typ_up);
    END IF;

    v_etape :='On recherche le code ut si pas imposé';
    IF p_cod_ut IS NULL THEN
        p_cod_ut := pc_bas_gen_cod_ut (p_cod_up    =>p_cod_up,
                                       p_typ_up    =>p_typ_up,
                                       p_typ_ut    =>p_typ_ut,
                                       p_cod_usn   =>p_cod_usn,
                                       p_cod_ut_sup=>p_cod_ut_sup,
                                       p_typ_ut_sup=>p_typ_ut_sup);
    END IF;

   	v_etape :='Calcul SSCC';
    IF p_id_sscc IS NOT NULL THEN
        v_id_sscc := p_id_sscc;
    ELSE
        v_etape :=' Génération du n° sscc ';
        
        IF su_global_pkv.v_niv_dbg >= 6 THEN
            su_bas_put_debug(v_nom_obj||v_etape ||'typ_ut '||p_typ_ut|| ' cod_ut '||p_cod_ut||' cod_usn '||p_cod_usn);
        END IF;

        v_id_sscc := pc_bas_gen_sscc ( p_cod_usn=>p_cod_usn,
                                       p_cod_soc=>p_cod_soc,
                                       p_typ_sscc=>'UT',
                                       p_typ_ut  =>p_typ_ut,
                                       p_cod_ut  =>p_cod_ut);
    END IF;
    
    v_etape := 'Construction du code-barre UT';
	v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'TYP_UT', p_typ_ut);
    v_add_ctx := su_ctx_pkg.su_bas_set_char(v_ctx,'COD_UT', p_cod_ut);

    v_ret := su_cc_pkg.su_bas_make_cc('PC_CB_UT',v_ctx, v_cb_ut);		
    IF v_ret <> 'OK' THEN
        RAISE err_except;
    END IF;
    
    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||'*** APRES GEN COD UT ET SSCC T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
        v_debut := SYSTIMESTAMP;
    END IF;
    
    v_etape:='construction cod_cnt_ut';
    v_cod_cnt_ut:=NVL(p_cod_cnt_ut,su_bas_gcl_pc_cfg_pal (p_cod_cfg_pal    => p_cod_cfg_pal_ut,
                                                          p_no_var_cfg_pal => p_no_var_cfg_pal_ut,
                                                          p_colonne        => 'COD_CNT_PAL'));

    v_etape := 'Création de l''UT SE';
    vr_ut.typ_ut            := p_typ_ut;
    vr_ut.cod_ut            := p_cod_ut;
    vr_ut.cod_usn_loc       := p_cod_usn;
    vr_ut.typ_ut_pere       := p_typ_ut_sup;
    vr_ut.cod_ut_pere       := p_cod_ut_sup;
    vr_ut.cod_mag_loc       := p_cod_mag_loc;
    vr_ut.cod_emp_loc       := p_cod_emp_loc;
	vr_ut.imm_ut_1          := v_cb_ut;
    -- imm_ut_2 doit toujours être le SSCC d'une UT d'expédition
	vr_ut.imm_ut_2          := v_id_sscc;
    vr_ut.cod_cnt           := v_cod_cnt_ut;

    IF p_no_dpt IS NOT NULL THEN
        v_dat_exp           := TO_DATE (su_bas_gcl_ex_ent_dpt (p_no_dpt => p_no_dpt,
                                                               p_colonne=> 'DAT_EXP'), su_bas_get_date_format);
    END IF;

    v_ret := se_bas_cre_ut (pr_ut       =>vr_ut,
                            p_lst_fils  =>NULL);

    IF v_ret <> 'OK' THEN
        RAISE err_except;
    END IF;

    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||'*** APRES SE_BAS_CRE_UT T='|| to_char((SYSTIMESTAMP-v_debut),'sssssxFF2'));
        v_debut := SYSTIMESTAMP;
    END IF;

    -- Si ce type d'UT peut recevoir un fils alors on cree la fiche pc_ut
    IF su_bas_gcl_se_typ_ut (p_typ_ut=>p_typ_ut,
                             p_colonne=>'LST_TYP_UT_FILS') IS NOT NULL THEN
        -- calcul tare ?
        IF p_tare_ut IS NULL AND p_cod_cnt_ut IS NOT NULL THEN
            v_tare_ut := su_bas_gcl_su_cnt (p_cod_cnt => p_cod_cnt_ut,
                                            p_colonne => 'TARE_STD');
        ELSE
            v_tare_ut := p_tare_ut;
        END IF;

        v_etape := 'Création de l''UT PC';
        v_ret := su_bas_ins_pc_ut(p_cod_ut          => p_cod_ut,
					          p_typ_ut              => p_typ_ut,
					          p_cod_ut_sup          => p_cod_ut_sup,
					          p_typ_ut_sup          => p_typ_ut_sup,
					          p_cod_up              => p_cod_up,
					          p_typ_up              => p_typ_up,
					          p_etat_pal_ut         => p_etat_pal_ut,
					          p_no_rmp              => p_no_rmp,
					          p_no_tav              => p_no_tav,
					          p_dat_reg             => p_dat_reg,
					          p_lib_zon_pal         => p_lib_zon_pal,
					          p_id_sscc             => v_id_sscc,
					          p_sgn_pal_ut          => p_sgn_pal_ut,
					          p_mode_pal_ut         => p_mode_pal_ut,
					          p_typ_pal_ut          => p_typ_pal_ut,
					          p_cod_cfg_pal_ut      => p_cod_cfg_pal_ut,
					          p_cle_rgp_pal_ut      => p_cle_rgp_pal_ut,
					          p_no_dpt              => p_no_dpt,
                              p_no_dpt_th           => p_no_dpt,
					          p_cod_tra             => p_cod_tra,
					          p_cod_tou             => p_cod_tou,
					          p_cod_usn             => p_cod_usn,
                              p_cod_soc             => p_cod_soc,
					          p_cod_ptp_1           => p_cod_ptp_1,
					          p_cod_ptp_2           => p_cod_ptp_2,
					          p_cod_cli             => p_cod_cli,
					          p_no_com              => p_no_com,
					          p_no_cmd              => p_no_cmd,
					          p_cod_pro             => p_cod_pro,
					          p_cod_va              => p_cod_va,
					          p_cod_vl              => p_cod_vl,
					          p_no_lig_cmd          => p_no_lig_cmd,
					          p_no_ord_ds_tou       => p_no_ord_ds_tou,
					          p_no_ord_ds_zg        => p_no_ord_ds_zg,
					          p_cod_zg              => p_cod_zg,
					          p_etat_atv_pc_ut      => NVL(p_etat_atv_pc_ut,su_bas_rch_etat_atv ('CREATION','PC_UT')),
					          p_qte_atv             => p_qte_atv,
					          p_qte_ref_atv         => p_qte_ref_atv,
					          p_cod_pss_afc         => p_cod_pss_afc,
                              p_cod_grp_pss         => p_cod_grp_pss,
					          p_cod_err_pc_ut       => p_cod_err_pc_ut,
                              p_no_var_cfg_pal_ut   => p_no_var_cfg_pal_ut,
                              p_ut_expedition       => p_ut_expedition,
                              p_dat_exp_ini         => v_dat_exp,
                              p_cod_cnt_ut          => v_cod_cnt_ut,
                              p_tare_ut             => v_tare_ut,
					          p_id_session_lock     => p_id_session_lock,
					          p_lst_fct_lock        => p_lst_fct_lock,
					          p_dat_lock            => p_dat_lock,
					          p_ope_lock            => p_ope_lock,
					          p_libre_pc_ut_1       => p_libre_pc_ut_1,
					          p_libre_pc_ut_2       => p_libre_pc_ut_2,
					          p_libre_pc_ut_3       => p_libre_pc_ut_3,
					          p_libre_pc_ut_4       => p_libre_pc_ut_4,
					          p_libre_pc_ut_5       => p_libre_pc_ut_5,
					          p_usr_lock            => p_usr_lock);

    END IF;

    IF v_ret <> 'OK' THEN
        RAISE err_except;
    END IF;

    IF su_global_pkv.v_niv_dbg >= 2 THEN
        su_bas_put_debug(v_nom_obj||'*** END T='|| to_char((SYSTIMESTAMP-v_debut_tot),'sssssxFF2'));
        v_debut := SYSTIMESTAMP;
    END IF;

    RETURN v_ret;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO my_pc_bas_cre_ut;--<ou non>
        su_bas_cre_ano (p_txt_ano         => 'EXCEPTION : ' || v_etape,
                        p_cod_err_ora_ano => SQLCODE,
                        p_lib_ano_1       => 'cod_up',
                        p_par_ano_1       => p_cod_up,
                        p_lib_ano_2       => 'typ_up',
                        p_par_ano_2       => p_typ_up,
						p_lib_ano_3       => 'cod_ut',
                        p_par_ano_3       => p_cod_ut,
                        p_lib_ano_4       => 'typ_ut',
                        p_par_ano_4       => p_typ_ut,
                        p_cod_err_su_ano  => v_cod_err_su_ano,
                        p_nom_obj         => v_nom_obj,
                        p_version         => v_version);
        IF v_ret='OK' OR v_ret IS null OR v_ret = 'ERROR' THEN
            RETURN NVL(v_cod_err_su_ano,'ERROR');
        ELSE
            RETURN v_ret;
        END IF;
END;

END; -- fin du package
/
show errors;




