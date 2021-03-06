-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema internetbanken
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema internetbanken
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `internetbanken` DEFAULT CHARACTER SET utf8 ;
USE `internetbanken` ;

-- -----------------------------------------------------
-- Table `internetbanken`.`Kund`
-- -----------------------------------------------------
DROP TABLE IF EXISTS kund;
CREATE TABLE IF NOT EXISTS `internetbanken`.`kund` (
  `idKund` INT NOT NULL AUTO_INCREMENT,
  `fornamn` VARCHAR(40) NOT NULL,
  `efternamn` VARCHAR(40) NOT NULL,
  `fodd` DATE NOT NULL,
  `adress` VARCHAR(40) NOT NULL,
  `ort` VARCHAR(40) NOT NULL,
  `pinkod` INT(4) NOT NULL,
  PRIMARY KEY (`idKund`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `internetbanken`.`Bankkonto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS bankkonto;
CREATE TABLE IF NOT EXISTS `internetbanken`.`bankkonto` (
  `idBankkonto` INT NOT NULL AUTO_INCREMENT,
  `saldo` INT NOT NULL DEFAULT 0,
  `Kund_idKund` INT NOT NULL,
  PRIMARY KEY (`idBankkonto`),
  INDEX `fk_Bankkonto_Kund_idx` (`Kund_idKund` ASC),
  CONSTRAINT `fk_Bankkonto_Kund`
    FOREIGN KEY (`Kund_idKund`)
    REFERENCES Kund (idKund)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

DROP TABLE IF EXISTS accountManager;
CREATE TABLE IF NOT EXISTS accountManager (
	accountID INT(11),
    customerID INT(11),
    FOREIGN KEY (customerID) REFERENCES Kund(idKund),
    FOREIGN KEY (accountID) REFERENCES bankkonto(idBankkonto)
);

-- -----------------------------------------------------
-- Table `internetbanken`.`Logg`
-- -----------------------------------------------------
DROP TABLE IF EXISTS logg;
CREATE TABLE IF NOT EXISTS `internetbanken`.`logg` (
	loggID INT(11) NOT NULL AUTO_INCREMENT,
  `action` VARCHAR(15) NOT NULL,
  `kontoNummer` INT NOT NULL,
  `saldo` INT NULL,
  `saldoTransaktion` INT NULL,
  `tid` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (loggID))
ENGINE = InnoDB;


DROP TABLE IF EXISTS calculateLogg;
CREATE TABLE IF NOT EXISTS `internetbanken`.`calculateLogg` (
	calculateID INT(11) NOT NULL AUTO_INCREMENT,
  `kontoId` INT NOT NULL,
  `rate` INT,
  `tid` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (calculateID))
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;



DROP TRIGGER IF EXISTS loggUpdate;
DROP TRIGGER IF EXISTS loggDelete;
DROP TRIGGER IF EXISTS loggInsert;


CREATE TRIGGER loggUpdate
AFTER UPDATE
ON bankkonto FOR EACH ROW
INSERT INTO logg (action, kontoNummer, saldo, saldoTransaktion)
VALUES ('UPDATE', NEW.idBankkonto, NEW.saldo, NEW.saldo - OLD.saldo);


CREATE TRIGGER loggDelete
AFTER DELETE
ON bankkonto FOR EACH ROW
INSERT INTO logg (action, kontoNummer, saldo, saldoTransaktion)
VALUES ('DELETE', OLD.idBankkonto, OLD.saldo, OLD.saldo);

CREATE TRIGGER loggInsert
AFTER INSERT
ON bankkonto FOR EACH ROW
INSERT INTO logg (action, kontoNummer, saldo, saldoTransaktion)
VALUES ('INSERT', NEW.idBankkonto, NEW.saldo, NEW.saldo);

DROP PROCEDURE IF EXISTS swish;
DELIMITER ;;
CREATE PROCEDURE swish(
	cidKund INT(11),
    cpinkod INT(4),
	tillIdBankkonto INT,
    franIdBankkonto INT,
    transaktionsPeng INT
)
BEGIN

DECLARE loginResult INT;
SET loginResult = loginUser2(cidKund, cpinkod);

IF loginResult IS NOT NULL 

THEN

START TRANSACTION;

UPDATE bankkonto
	SET saldo = saldo + transaktionsPeng
WHERE
	idBankkonto = tillIdBankkonto;

UPDATE bankkonto
	SET saldo = saldo -  (transaktionsPeng * 1.02)
WHERE
	idBankkonto = franIdBankkonto;

UPDATE bankkonto
	SET saldo = saldo + ((transaktionsPeng * 1.02) - transaktionsPeng)
WHERE
	Kund_idKund = "1";

COMMIT;

ELSE 
ROLLBACK;

END IF;

END
;;
DELIMITER ;



-- ------------------------- --
-- Stored Procedures --
-- ------------------------- --

DROP PROCEDURE IF EXISTS getAllAccountsOnUserID;
DROP PROCEDURE IF EXISTS createUser;
DROP PROCEDURE IF EXISTS shareAccountWithUser;
DROP PROCEDURE IF EXISTS addAccountToUser;

DELIMITER //
CREATE PROCEDURE getAllAccountsOnUserID(
	id INT(11)
)
BEGIN
	SELECT
		am.accountID,
		b.idBankkonto,
		b.saldo,
		CONCAT(k.fornamn, ' ', k.efternamn, ' (Kund ID: ', k.idKund, ')') AS holder
		FROM bankkonto AS b
			JOIN accountManager AS am
				ON am.accountID = b.idBankkonto
			JOIN Kund AS k
				ON k.idKund = b.Kund_idKund
		WHERE  am.customerID = id
	;
END
//

DELIMITER ;

DELIMITER //
CREATE PROCEDURE createUser(
  cFornamn VARCHAR(40),
  cEfternamn VARCHAR(40),
  cFodd DATE,
  cAdress VARCHAR(40),
  cOrt VARCHAR(40),
  cPinkod INT(4)
)
BEGIN
	INSERT INTO Kund (fornamn, efternamn, fodd, adress, ort, pinkod)
    VALUES (cFornamn, cEfternamn, cFodd, cAdress, cOrt, cPinkod);

    SELECT idKund AS id INTO @kundID
	FROM Kund
	ORDER BY idKund
    DESC LIMIT 1;

    INSERT INTO bankkonto(Kund_idKund)
    VALUES (@kundID);

    SELECT idBankkonto AS id INTO @bankID
	FROM bankkonto
	ORDER BY idBankkonto
    DESC LIMIT 1;

    INSERT INTO accountManager(accountID, customerID)
	VALUES (@bankID, @kundID);


END
//

DELIMITER ;

DELIMITER //
CREATE PROCEDURE shareAccountWithUser(
  userID INT(11),
  accID INT(11)
)
BEGIN
    INSERT INTO accountManager(accountID, customerID)
	VALUES (userID, accID);
END
//

DELIMITER ;

DELIMITER //
CREATE PROCEDURE addAccountToUser(
  userID INT(11)
)
BEGIN
	 INSERT INTO bankkonto(Kund_idKund)
    VALUES (userID);

    SELECT idBankkonto AS id INTO @bankID
	FROM bankkonto
	ORDER BY idBankkonto
    DESC LIMIT 1;

    INSERT INTO accountManager(accountID, customerID)
	VALUES (@bankID, userID);
END
//
DELIMITER ;

DROP PROCEDURE IF EXISTS loginUser;
DELIMITER ;;
CREATE PROCEDURE loginUser(
    cidKund INT(11),
    cpinkod INT(4)
)
BEGIN
    SELECT
    idKund AS kundID
    FROM kund
    WHERE
    idKund = cidKund
      AND pinkod = cPinkod
    ;
END
;;
DELIMITER ;

DROP FUNCTION IF EXISTS loginUser2;
DELIMITER ;;
CREATE FUNCTION loginUser2(
    cidKund INT(11),
    cpinkod INT(4)
)
RETURNS INT
BEGIN
    IF (SELECT idKund 
    FROM kund
    WHERE idKund = cidKund
    AND pinkod = cpinkod) = cidKund
    THEN RETURN cidKund;
    ELSE
    RETURN NULL;
    
    END IF;
END
;;
DELIMITER ;


DROP PROCEDURE IF EXISTS depositMoney;
DELIMITER ;;
CREATE PROCEDURE depositMoney(
    dIdBankkonto INT(11),
    dAmount INT(11)
)
BEGIN

	START TRANSACTION;
    
    UPDATE Bankkonto
    SET saldo = saldo + dAmount
    WHERE IdBankkonto = dIdBankkonto
    ;
    
    COMMIT;
END
;;
DELIMITER ;



DROP PROCEDURE IF EXISTS transferMoney;
DELIMITER ;;
CREATE PROCEDURE transferMoney(
    dOwnBankkonto INT(11),
	dIdBankkonto INT(11),
    dAmount INT(11)
   
)
BEGIN

	START TRANSACTION;
    
    UPDATE Bankkonto
    SET saldo = saldo + dAmount
    WHERE IdBankkonto = dIdBankkonto
    ;
    
    UPDATE Bankkonto
    SET saldo = saldo - (dAmount * 1.03)
    WHERE idBankkonto = dOwnBankkonto
    ;
    
    UPDATE Bankkonto
    SET saldo = saldo + ((dAmount * 1.03) - dAmount )
    WHERE idBankkonto = 1
    
    ;
    
    COMMIT;
END
;;
DELIMITER ;

DROP PROCEDURE IF EXISTS getAdministationInfo;
DELIMITER ;;
CREATE PROCEDURE getAdministationInfo(
)
BEGIN
	SELECT 
	*
    FROM logg 
	ORDER BY loggID DESC;
END
;;
DELIMITER ;

DROP PROCEDURE IF EXISTS getAccountInfo;
DELIMITER ;;
CREATE PROCEDURE getAccountInfo(
	accID INT(11)
)
BEGIN
	SELECT 
	am.accountID  AS ID,
	CONCAT(k.fornamn, ' ', k.efternamn, ' (Kund ID: ', k.idKund, ')') AS namn
    FROM accountManager AS am
		JOIN Kund AS k
			ON k.idKund = am.customerID
	WHERE am.accountID = accID
    ;
END
;;
DELIMITER ;

DROP PROCEDURE IF EXISTS 
DELIMITER ;;
CREATE PROCEDURE calculateInterest(
	interestRate INT(11),
    dateOfCalculation TIMESTAMP
)
BEGIN
	SELECT 
		(interestRate * b.saldo) / 365 AS rate,
        dateOfCalculation AS date,
        b.idBankkonto AS id
        FROM bankkonto AS b;
	
    INSERT INTO calculateLogg (kontoId, rate) 
    SELECT idBankkonto, (interestRate * saldo) / 365
    FROM bankkonto;
END
;;
DELIMITER ;

DROP PROCEDURE IF EXISTS calculateSingleInterest;
DELIMITER ;;
CREATE PROCEDURE calculateSingleInterest(
	accID INT(11),
    interestRate INT(11),
    dateOfCalculation TIMESTAMP
)
BEGIN
	SELECT 
		(interestRate * saldo) / 365 AS rate,
        dateOfCalculation AS date,
        idBankkonto as id
        FROM bankkonto
        WHERE idBankkonto = accID;
        
	INSERT INTO calculateLogg (kontoId, rate) 
    SELECT idBankkonto, (interestRate * saldo) / 365
    FROM bankkonto 
    WHERE idBankkonto = accID;
    
END
;;
DELIMITER ;


DROP PROCEDURE IF EXISTS showCalculateForYear;
DELIMITER ;;
CREATE PROCEDURE showCalculateForYear(
	aYear int(4)
)
BEGIN
	Select * FROM calculateLogg
    WHERE YEAR(tid) = aYear;
END
;;
DELIMITER ;



DROP PROCEDURE IF EXISTS showCalculateForDay;
DELIMITER ;;
CREATE PROCEDURE showCalculateForDay(
	aDay int(4)
)
BEGIN
	Select * FROM calculateLogg
    WHERE DAY(tid) = aDay;
END
;;
DELIMITER ;




